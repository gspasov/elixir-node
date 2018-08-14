defmodule Aecore.Naming.NameCommitment do
  @moduledoc """
  Aecore naming name commitment structure
  """

  alias Aecore.Naming.{NameCommitment, NameUtil}
  alias Aeutil.Bits
  alias Aeutil.Hash
  alias Aeutil.Serialization
  alias Aecore.Chain.Identifier

  @version 1

  @type salt :: integer()

  @type t :: %NameCommitment{
          hash: binary(),
          owner: Wallet.pubkey(),
          created: non_neg_integer(),
          expires: non_neg_integer()
        }

  defstruct [:hash, :owner, :created, :expires]
  use ExConstructor
  use Aecore.Util.Serializable

  @spec create(
          binary(),
          Wallet.pubkey(),
          non_neg_integer(),
          non_neg_integer()
        ) :: t()
  def create(hash, owner, created, expires) do
    identified_hash = Identifier.create_identity(hash, :commitment)

    %NameCommitment{
      :hash => identified_hash,
      :owner => owner,
      :created => created,
      :expires => expires
    }
  end

  @spec commitment_hash(String.t(), salt()) :: {:ok, binary()} | {:error, String.t()}
  def commitment_hash(name, name_salt) when is_integer(name_salt) do
    case NameUtil.normalized_namehash(name) do
      {:ok, hash} ->
        {:ok, Hash.hash(hash <> <<name_salt::integer-size(256)>>)}

      err ->
        err
    end
  end

  def base58c_encode_commitment(bin) do
    Bits.encode58c("cm", bin)
  end

  def base58c_decode_commitment(<<"cm$", payload::binary>>) do
    Bits.decode58(payload)
  end

  def base58c_decode_commitment(_) do
    {:error, "Wrong data"}
  end

  def encode_to_list(%NameCommitment{} = name_commitment) do
    [
      :binary.encode_unsigned(@version),
      name_commitment.owner,
      :binary.encode_unsigned(name_commitment.created),
      :binary.encode_unsigned(name_commitment.expires)
    ]
  end

  def decode_from_list(@version, [encoded_owner, created, expires]) do
    {:ok,
     %NameCommitment{
       owner: encoded_owner,
       created: :binary.decode_unsigned(created),
       expires: :binary.decode_unsigned(expires)
     }}
  end

  def decode_from_list(@version, data) do
    {:error, "#{__MODULE__}: decode_from_list: Invalid serialization: #{inspect(data)}"}
  end

  def decode_from_list(version, _) do
    {:error, "#{__MODULE__}: decode_from_list: Unknown version #{version}"}
  end
end