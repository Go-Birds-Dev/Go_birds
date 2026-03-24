import tensorflow as tf
import os

model_configs = [
    {
        "path": "./0vgg16_01_l_128_acc_32_42_data04",
        "output_name": "vgg16_aves.tflite"
    },
    {
        "path": "./mobilenetv2_aves_01_l_128_acc_32_42_data04",
        "output_name": "mobilenet_v2_aves.tflite"
    }
]

output_dir = "./assets/models"
os.makedirs(output_dir, exist_ok=True)

for config in model_configs:
    model_dir = config["path"]
    output_name = config["output_name"]
    model_name = os.path.basename(model_dir)
    
    print(f"Paso 1: Cargando SavedModel: {model_name}")
    model = tf.saved_model.load(model_dir)
    
    # Convertir SavedModel a función concreta
    concrete_func = model.signatures['serving_default']
    
    print(f"Paso 2: Convirtiendo a TFLite (congelado): {output_name}")
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.experimental_enable_resource_variables = False
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    
    tflite_model = converter.convert()
    
    output_path = os.path.join(output_dir, output_name)
    with open(output_path, "wb") as f:
        f.write(tflite_model)
    print(f"✅ {model_name} → {output_path}\n")