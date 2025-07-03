using System.IO;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class BinarySaveService : ISaveService
{
    string GetPath(string key) => Path.Combine(Application.persistentDataPath, key + ".bin");

    public UniTask<T> LoadAsync<T>(string key) where T : IBinarySerializable, new()
    {
        var path = GetPath(key);
        if (!File.Exists(path))
            return UniTask.FromResult(default(T));

        using var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 4096, false);
        using var br = new BinaryReader(fs);
        var obj = new T();
        obj.Deserialize(br);
        return UniTask.FromResult(obj);
    }

    public UniTask SaveAsync<T>(string key, T data) where T : IBinarySerializable
    {
        var path = GetPath(key);
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        using var fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None, 4096, false);
        using var bw = new BinaryWriter(fs);
        data.Serialize(bw);
        return UniTask.CompletedTask;
    }
}