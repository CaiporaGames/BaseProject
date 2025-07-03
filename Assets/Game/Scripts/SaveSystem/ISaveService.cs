using Cysharp.Threading.Tasks;

public interface ISaveService
{
    /// <summary>
    /// Load a typed data object by key (e.g. “playerProfile”).
    /// Returns default(T) if no file exists.
    /// </summary>
    UniTask<T> LoadAsync<T>(string key) where T : IBinarySerializable , new();

    /// <summary>
    /// Persist the object under the given key.
    /// Overwrites any existing file.
    /// </summary>
    UniTask SaveAsync<T>(string key, T data) where T : IBinarySerializable;
}
