Shader "Unity Shader Book/Chapter 9/AttenuationAndShadowUseBuildInFunctions" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader {
        Pass {
            // Pass for ambient light & first pixel light (directional light)

            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM

            #pragma multi_compile_fwdbase
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert(a2v v) {
                v2f o;
                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                // Transform the normal from object space to world space
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                // Transform the vertex from object space to world space
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // Pass shadow coordinate to pixel shader
                TRANSFER_SHADOW(o);

                return o;
            }


            fixed4 frag(v2f i) : SV_Target {
                // Get ambient term
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // Compute diffuse term
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                // Get the view direction in world space
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // Get the half direction in world space
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                
                // Compute specular term
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);


            }

            ENDCG
        }
        Pass{
            // Pass for other pixel lights
            Tags { "LightMode" = "ForwardAdd"}

            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd_fullshadows // Create the shadows in the additional pass
            //#pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc" // Using unity_WorldToLight 

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert(a2v v) {
                v2f o;
                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                // Transform the normal from object space to world space
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                // Transform the vertex from object space to world space
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }


            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif

                // Compute diffuse term
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                // Get the view direction in world space
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // Get the half direction in world space
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                
                // Compute specular term
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG

            
        }
    }
    Fallback "Specular"
}