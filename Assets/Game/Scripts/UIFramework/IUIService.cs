using Cysharp.Threading.Tasks;

public interface IUIService
{
    /// <summary>Registers a controller under a key.</summary>
    void Register(string key, IUIController controller);

    /// <summary>Show a registered screen by key.</summary>
    UniTask ShowScreenAsync(string key, object payload = null);

    /// <summary>Hide a registered screen by key.</summary>
    UniTask HideScreenAsync(string key);
}
