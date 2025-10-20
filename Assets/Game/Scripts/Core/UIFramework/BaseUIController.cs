using Cysharp.Threading.Tasks;
using UnityEngine;

/// <summary>
/// Base class for MonoBehaviour-based screens
/// </summary>
public abstract class BaseUIController : MonoBehaviour, IUIController
{
    public CanvasGroup canvasGroup;

    protected virtual void Awake()
    {
        //gameObject.SetActive(false);
        if (canvasGroup == null)
            canvasGroup = GetComponent<CanvasGroup>();
    }

    public virtual async UniTask InitializeAsync()
    {
        // Override for loading assets or bindings
        await UniTask.Yield();
    }

    public virtual async UniTask ShowAsync<T>(T data = default)
    {
        await Fade(1);
    }

    public virtual async UniTask HideAsync<T>(T data = default)
    {
        await Fade(0);
    }

    private async UniTask Fade(float to)
    {
        float from = canvasGroup.alpha;

        if (Mathf.Approximately(from, to))
        {
            canvasGroup.interactable = to == 1;
            canvasGroup.blocksRaycasts = to == 1;
            return;
        }

        float t = 0f;
        const float duration = 0.25f;

        while (t < duration)
        {
            t += Time.deltaTime;
            canvasGroup.alpha = Mathf.Lerp(from, to, t / duration);
            canvasGroup.interactable = to == 1;
            canvasGroup.blocksRaycasts = to == 1;
            await UniTask.Yield();
        }

        canvasGroup.alpha = to;
        canvasGroup.interactable = to == 1;
        canvasGroup.blocksRaycasts = to == 1;
    }

}