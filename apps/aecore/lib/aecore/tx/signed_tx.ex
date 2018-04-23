defmodule Aecore.Tx.SignedTx do
  @moduledoc """
  Aecore structure of a signed transaction.
  """

  alias Aecore.Tx.SignedTx
  alias Aecore.Tx.DataTx
  alias Aecore.Tx.SignedTx
  alias Aewallet.Signing
  alias Aeutil.Serialization
  alias Aeutil.Bits
  alias Aeutil.Hash

  require Logger

  @type t :: %SignedTx{
          data: DataTx.t(),
          signature: binary()
        }

  @doc """
  Definition of Aecore SignedTx structure

  ## Parameters
     - data: Aecore %SpendTx{} structure
     - signature: Signed %SpendTx{} with the private key of the sender
  """
  defstruct [:data, :signature]
  use ExConstructor

  @spec is_coinbase?(SignedTx.t()) :: boolean()
  def is_coinbase?(%{data: %{sender: key}, signature: signature}) do
    key == nil && signature == nil
  end

  @doc """
  Checks weather the signature is correct.
  """
  @spec validate(SignedTx.t()) :: :ok | {:error, String.t()}
  def validate(%SignedTx{data: data} = tx) do
    if Signing.verify(Serialization.rlp_encode(data), tx.signature, data.sender) do
      :ok
    else
      {:error, "#{__MODULE__}: Can't verify the signature
      with the following public key: #{inspect(data.sender)}"}
    end
  end

  @doc """
  Takes the transaction that needs to be signed
  and the private key of the sender.
  Returns a signed tx

  ## Parameters
     - tx: The transaction data that it's going to be signed
     - priv_key: The priv key to sign with

  """
  @spec sign_tx(DataTx.t(), binary()) :: {:ok, SignedTx.t()}
  def sign_tx(%DataTx{} = tx, priv_key) when byte_size(priv_key) == 32 do
    signature = Signing.sign(Serialization.rlp_encode(tx), priv_key)

    if byte_size(signature) <= get_sign_max_size() do
      {:ok, %SignedTx{data: tx, signature: signature}}
    else
      {:error, "Wrong signature size"}
    end
  end

  def sign_tx(%DataTx{} = _tx, priv_key) do
    {:error, "#{__MODULE__}: Wrong key size: #{inspect(priv_key)}"}
  end

  def sign_tx(tx, _priv_key) do
    {:error, "#{__MODULE__}: Wrong Transaction data structure: #{inspect(tx)}"}
  end

  def get_sign_max_size do
    Application.get_env(:aecore, :signed_tx)[:sign_max_size]
  end

  @spec hash_tx(SignedTx.t()) :: binary()
  def hash_tx(%SignedTx{data: data}) do
    Hash.hash(Serialization.pack_binary(data))
  end

  @spec reward(DataTx.t(), Account.t()) :: Account.t()
  def reward(%DataTx{type: type, payload: payload}, account_state) do
    type.reward(payload, account_state)
  end

  def base58c_encode(bin) do
    Bits.encode58c("tx", bin)
  end

  def base58c_decode(<<"tx$", payload::binary>>) do
    Bits.decode58(payload)
  end

  def base58c_decode(bin) do
    {:error, "#{__MODULE__}: Wrong data: #{inspect(bin)}"}
  end

  def base58c_encode_root(bin) do
    Bits.encode58c("bx", bin)
  end

  def base58c_decode_root(<<"bx$", payload::binary>>) do
    Bits.decode58(payload)
  end

  def base58c_decode_root(bin) do
    {:error, "#{__MODULE__}: Wrong data: #{inspect(bin)}"}
  end

  def base58c_encode_signature(bin) do
    if bin == nil do
      nil
    else
      Bits.encode58c("sg", bin)
    end
  end

  def base58c_decode_signature(<<"sg$", payload::binary>>) do
    Bits.decode58(payload)
  end

  def base58c_decode_signature(_) do
    {:error, "Wrong data"}
  end
end
