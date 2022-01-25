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

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup
            #include "UnityCG.cginc"

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
