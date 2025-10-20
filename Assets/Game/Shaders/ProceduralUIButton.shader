Shader "UI/Procedural/UIButton_Full"
{
    /********************************************************************
     *  PART 0 ▸ PROPERTIES (Inspector-exposed)
     *******************************************************************/
    Properties
    {
        /* ▸▸ Fill gradient ------------------------------------------- */
        _FillTop    ("Fill Top"      , Color) = (0.95,0.55,1 ,1)
        _FillBottom ("Fill Bottom"   , Color) = (0.55,0.25,0.9,1)

        /* ▸▸ Outline -------------------------------------------------- */
        _OutlineColor    ("Outline"       , Color)          = (0,0,0,1)
        _OutlineThickness("Outline Width" , Range(0,0.5))   = 0.05
        _CornerRadius    ("Corner Radius" , Range(0,0.5))   = 0.18
        _EdgeSmoothness  ("Edge Smooth"   , Range(0,0.05))  = 0.01

        /* ▸▸ Glow rim ------------------------------------------------- */
        _GlowColor    ("Glow Color"   , Color)          = (1,0.7,1,1)
        _GlowWidth    ("Glow Width"   , Range(0,0.4))  = 0.05
        _GlowSpeed    ("Glow Speed"   , Range(0,10))   = 3
        _GlowStrength ("Glow Strength", Range(0,2))    = 0.8

        /* ▸▸ Shine stripe -------------------------------------------- */
        _StripeColor   ("Stripe Color"   , Color)        = (1,1,1,1)
        _StripeWidth   ("Stripe Width"   , Range(0,1))   = 0.25
        _StripeSpeed   ("Stripe Speed"   , Range(0,10))  = 2
        _StripeAngle   ("Stripe Angle°"  , Range(0,360)) = 45
        _StripeStrength("Stripe Strength", Range(0,2))   = 1

        _ShadowColor("Shadow Color", Color) = (0, 0, 0, 0.5)
        _ShadowOffset("Shadow Offset", Vector) = (0.01, -0.01, 0, 0)
        _ShadowBlur("Shadow Blur", Range(0, 0.1)) = 0.03

        _HighlightColor("Highlight Color", Color) = (1,1,1,0.4)
        _HighlightPos  ("Highlight Position", Vector) = (0.15, 0.85, 0, 0)
        _HighlightSize ("Highlight Size", Vector) = (0.1, 0.06, 0, 0)


    }

    /********************************************************************
     *  PART 1 ▸ SUBSHADER SETUP
     *******************************************************************/
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100
        //--------------------------------- SHADOW PASS ------------------------------
Pass
{
    ZWrite Off
    Blend SrcAlpha OneMinusSrcAlpha
    Cull Off

    CGPROGRAM
    #pragma vertex   vert_shadow
    #pragma fragment frag_shadow
    #include "UnityCG.cginc"

    /* shadow-only uniforms */
    fixed4 _ShadowColor;
    float4 _ShadowOffset;      // xy in *pixels*
    float  _ShadowBlur;
    float  _CornerRadius;



    //---------------- helper: rounded box SDF ----------------
    float sdRoundBox(float2 uv, float2 size, float r)
    {
        float2 q = abs(uv - 0.5) - (size*0.5 - r);
        return length(max(q,0)) - r;
    }

    struct appdata { float4 vertex:POSITION; float2 uv:TEXCOORD0; };
    struct v2f     { float4 pos:SV_POSITION; float2 uv:TEXCOORD0; };

    v2f vert_shadow(appdata v)
    {
        v2f o;
        
        /* ---------- 1️⃣ move quad in clip-space ---------- */
        float2 pixelOffset   = _ShadowOffset.xy;          // e.g. (2,-2) pixels
        float2 clipOffset    = pixelOffset * 2.0 / _ScreenParams.xy; // → NDC units
        float4 pos           = UnityObjectToClipPos(v.vertex);
        pos.xy              += clipOffset * pos.w;        // apply at homogeneous depth
        o.pos = pos;

        /* ---------- 2️⃣ keep UV unchanged  -------------- */
        o.uv  = v.uv;  // we still need it for the SDF
        return o;
    }

    fixed4 frag_shadow(v2f i) : SV_Target
    {
        float dist  = sdRoundBox(i.uv, 1, _CornerRadius);
        float alpha = smoothstep(_ShadowBlur, 0.0, dist);   // soft edge
        return fixed4(_ShadowColor.rgb, _ShadowColor.a * alpha);
    }
    ENDCG
}

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha    // standard UI blend
            Cull Off

            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            /************************************************************
             *  PART 2 ▸ STRUCTS & UNIFORMS
             ***********************************************************/
            struct appdata { float4 vertex:POSITION; float2 uv:TEXCOORD0; };
            struct v2f     { float4 pos:SV_POSITION; float2 uv:TEXCOORD0; };

            /* uniforms (auto-populated from Properties) */
            fixed4 _FillTop, _FillBottom;
            fixed4 _OutlineColor;
            float  _OutlineThickness, _CornerRadius, _EdgeSmoothness;

            fixed4 _GlowColor;   float _GlowWidth,   _GlowSpeed,   _GlowStrength;
            fixed4 _StripeColor; float _StripeWidth, _StripeSpeed, _StripeAngle, _StripeStrength;

                fixed4 _HighlightColor;
float4 _HighlightPos;  // xy = center (in UV)
float4 _HighlightSize; // xy = width & height (radius)

            /************************************************************
             *  PART 3 ▸ HELPER: Rounded-box signed-distance
             ***********************************************************/
            float sdRoundBox(float2 uv, float2 size, float r)
            {
                /* uv in [0,1] space, size = 1×1 because RawImage covers full quad */
                float2 q = abs(uv - 0.5) - (size*0.5 - r);
                return length(max(q,0)) - r;
            }

            /************************************************************
             *  PART 4 ▸ VERTEX
             ***********************************************************/
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.uv;
                return o;
            }

            /************************************************************
             *  PART 5 ▸ FRAGMENT – assembled in stages
             ***********************************************************/
            fixed4 frag (v2f i) : SV_Target
            {
                /* -- 5.1 Shape & outline ------------------------------------ */
                float  dist   = sdRoundBox(i.uv, 1, _CornerRadius);
                float  aFill  = smoothstep(_EdgeSmoothness, 0, dist);                 // inside
                float  aEdge  = smoothstep(_EdgeSmoothness, 0, abs(dist)-_OutlineThickness);

                /* Gradient fill color (vertical: top-to-bottom) */
                fixed4 fillCol = lerp(_FillBottom, _FillTop, i.uv.y);
fixed4 col = lerp(_OutlineColor, fillCol, aEdge);  // outline then fill
                col.a *= aFill; 

                
                // Oval highlight mask using UV distance
                float2 diff = (i.uv - _HighlightPos.xy) / _HighlightSize.xy;
                float d = dot(diff, diff); // ellipse mask (centered at pos)
                float hMask = saturate(1.0 - d); // radial falloff

                // Optional soft edge
                hMask = smoothstep(0.0, 1.0, hMask);

                // Additive blend on top of base color
                col.rgb = lerp(col.rgb, _HighlightColor.rgb, hMask * _HighlightColor.a);
                col.a   = max(col.a, hMask * _HighlightColor.a); // keep alpha consistent


                                                   // clip outside

                /* -- 5.2 Glow rim ------------------------------------------- */
                float glowMask  = 1 - smoothstep(0, _GlowWidth, abs(dist)-_OutlineThickness);
                float glowPulse = 0.5 + 0.5 * sin(_Time.y * _GlowSpeed);
                float glowA     = glowMask * glowPulse * _GlowStrength;

                col.rgb = lerp(col.rgb, _GlowColor.rgb, glowA);
                col.a   = max(col.a, glowA);                       // maintain alpha

                /* -- 5.3 Stripe shine --------------------------------------- */
                float rad = radians(_StripeAngle);
                float2 dir = float2(cos(rad), sin(rad));           // unit direction
                float  slide = dot(i.uv - 0.5, dir) + frac(_Time.y * _StripeSpeed);
                slide = frac(slide + 0.5) - 0.5;                   // wrap to –0.5..0.5

                float stripeMask = smoothstep(_StripeWidth, 0, abs(slide));
                float stripeA    = stripeMask * aFill * _StripeStrength;

                col.rgb = lerp(col.rgb, _StripeColor.rgb, stripeA);
                col.a   = max(col.a, stripeA);

                return col;
            }
            ENDCG
        }
    }
}
