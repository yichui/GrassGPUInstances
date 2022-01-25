Shader "URP_GPU_Instance/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            ZWrite On
            ZTest On
            Cull Off
        
            HLSLPROGRAM

            
            //#include "UnityCG.cginc"
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // #include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup


            

            #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                struct GrassInfo {
                    float4x4 localToTerrian;
                    float4 texParams;
                };
                StructuredBuffer<GrassInfo> _GrassInfos;
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                uint instanceID : SV_InstanceID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };


            #pragma vertex vert
            #pragma fragment frag


           
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float2 _GrassQuadSize;

            v2f vert (appdata v)
            {
                v2f o;


                float3 vertexOS = v.vertex;


                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                

                
                //通过_GrassQuadSize来控制面片大小
                vertexOS.xy = vertexOS.xy * _GrassQuadSize;
                float localVertexHeight = positionOS.y;
#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                GrassInfo grassInfo = _GrassInfos[instanceID];

                //将顶点和法线从Quad本地空间变换到Terrian本地空间
                positionOS = mul(grassInfo.localToTerrian, float4(positionOS, 1)).xyz;
                normalOS = mul(grassInfo.localToTerrian, float4(normalOS, 0)).xyz;

                //UV偏移缩放
                uv = uv * grassInfo.texParams.xy + grassInfo.texParams.zw;

#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDHLSL
        }
    }
}
