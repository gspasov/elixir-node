defmodule Aehttpserver.Web.Notify do
  @moduledoc """
  Contains functionality for broadcasting new blocks/transactions via websocket.
  """

  alias Aecore.Account.Tx.SpendTx
  alias Aecore.Oracle.Tx.OracleQueryTx
  alias Aecore.Naming.Tx.NameTransferTx
  alias Aeutil.Serialization
  alias Aehttpserver.Web.Endpoint
  alias Aecore.Account.Account

  def broadcast_new_transaction_in_the_pool(tx) do
    broadcast_tx(tx, true)

    broadcast_tx(tx, false)

    Endpoint.broadcast!("room:notifications", "new_transaction_in_the_pool", %{
      "body" => Serialization.tx(tx, :serialize)
    })
  end

  def broadcast_new_block_added_to_chain_and_new_mined_tx(block) do
    Enum.each(block.txs, fn tx ->
      Endpoint.broadcast!("room:notifications", "new_mined_tx_everyone", %{
        "body" => Serialization.tx(tx, :serialize)
      })

      broadcast_tx(tx, true)
    end)

    Endpoint.broadcast!("room:notifications", "new_block_added_to_chain", %{
      "body" => Serialization.block(block, :serialize)
    })
  end

  def broadcast_tx(tx, is_to_sender) do
    if is_to_sender do
      if Map.has_key?(tx.data, :sender) && tx.data.sender != nil do
        Endpoint.broadcast!(
          "room:notifications",
          "new_tx:" <> Account.base58c_encode(tx.data.sender),
          %{"body" => Serialization.tx(tx, :serialize)}
        )
      end
    else
      case tx.data.payload do
        %SpendTx{} ->
          Endpoint.broadcast!(
            "room:notifications",
            "new_tx:" <> Account.base58c_encode(tx.data.payload.receiver),
            %{"body" => Serialization.tx(tx, :serialize)}
          )

        %OracleQueryTx{} ->
          Endpoint.broadcast!(
            "room:notifications",
            "new_tx:" <> Account.base58c_encode(tx.data.payload.oracle_address),
            %{"body" => Serialization.tx(tx, :serialize)}
          )

        %NameTransferTx{} ->
          Endpoint.broadcast!(
            "room:notifications",
            "new_tx:" <> Account.base58c_encode(tx.data.payload.target),
            %{"body" => Serialization.tx(tx, :serialize)}
          )

        _ ->
          :ok
      end
    end
  end
end
