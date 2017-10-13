defmodule Aecore.Miner.Worker do

  use GenStateMachine, callback_mode: :state_functions

  alias Aecore.Chain.Worker, as: Chain
  alias Aecore.Utils.Blockchain.BlockValidation
  alias Aecore.Utils.Blockchain.Difficulty
  alias Aecore.Block.Headers
  alias Aecore.Block.Blocks
  alias Aecore.Pow.Hashcash
  alias Aecore.Txs.Pool.Worker, as: Pool
  alias Aecore.Chain.ChainState

  def start_link() do
    GenStateMachine.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def resume() do
    GenStateMachine.call(__MODULE__, :start)
  end

  def suspend() do
    GenStateMachine.call(__MODULE__, :suspend)
  end

  def init(data) do
    GenStateMachine.cast(__MODULE__, :idle)
    {:ok, :running, data}
  end

  def get_state() do
    GenStateMachine.call(__MODULE__, :get_state)
  end

  ## Idle ##
   def idle({:call, from}, :start , data) do
     IO.puts "Mining resuming by user"
     GenStateMachine.cast(__MODULE__, :mine)
     {:next_state, :running, data, [{:reply, from, :ok}]}
   end

   def idle({:call, from}, :suspend , data) do
     {:next_state, :idle, data, [{:reply, from, :not_started}]}
   end

   def idle({:call, from}, :get_state, data) do
     {:keep_state_and_data, [{:reply, from, {:state, :idle}}]}
   end

   def idle({:call, from}, _ , data) do
     {:next_state, :idle, data, [{:reply, from, :not_started}]}
   end

   def idle(type, state , data) do
     {:next_state, :idle, data}
   end

   ## Running ##
   def running(:cast, :mine, data) do
     mine_next_block()
     GenStateMachine.cast(__MODULE__,:mine)
     {:next_state, :running, data}
   end

   def running({:call, from}, :get_state, data) do
     {:keep_state_and_data, [{:reply, from, {:state, :running}}]}
   end

   def running({:call, from}, :start, data) do
     {:next_state, :running, data, [{:reply, from, :already_started}]}
   end

   def running({:call, from}, :suspend, data) do
     IO.puts "Mined stop by user"
     {:next_state, :idle, data, [{:reply, from, :ok}]}
   end

   def running({:call, from}, _, data) do
     {:next_state, :running, data, [{:reply, from, :not_suported}]}
   end

   def running(_, _, data) do
     {:next_state, :idle, data}
   end

  ## Internal
  @spec mine_next_block() :: :ok
  defp mine_next_block() do
    chain_state = Chain.chain_state()

    txs_list = Map.values(Pool.get_and_empty_pool())

    blocks_for_difficulty_calculation = Chain.get_blocks_for_difficulty_calculation()
    {latest_block, previous_block} = Chain.get_prior_blocks_for_validity_check()

    if(!(previous_block == nil)) do
      BlockValidation.validate_block!(latest_block, previous_block, chain_state)
    end

    valid_txs = BlockValidation.filter_invalid_transactions(txs_list)
    root_hash = BlockValidation.calculate_root_hash(valid_txs)

    new_block_state = ChainState.calculate_block_state(valid_txs)
    new_chain_state = ChainState.calculate_chain_state(new_block_state, chain_state)
    chain_state_hash = ChainState.calculate_chain_state_hash(new_chain_state)

    latest_block_hash = BlockValidation.block_header_hash(latest_block.header)
    difficulty = Difficulty.calculate_next_difficulty(blocks_for_difficulty_calculation)

    unmined_header = Headers.new(latest_block.header.height + 1, latest_block_hash,
      root_hash, chain_state_hash, difficulty, 0, 1)
    {:ok, mined_header} = Hashcash.generate(unmined_header)
    {:ok, block} = Blocks.new(mined_header, valid_txs)

    IO.inspect("block: #{block.header.height} difficulty: #{block.header.difficulty_target}")
    Chain.add_block(block)
  end

end
