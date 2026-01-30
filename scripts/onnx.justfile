gdrive_runtime_arm64-v8a_api27 := "1q8SHkbCjDVQsuaNxJ9bpoi5MeBgpX2o1"

@onnx target:
	@echo "ONNX: running {{target}}"
	@just "onnx-{{target}}"

# Builds the ONNX Runtime for Android for a specific ABI and API level.
[working-directory: '.']
@onnx-build-runtime abi="arm64-v8a" api-level="27":
    @echo "Setting up environment for building ONNX Runtime..."
    @chmod +x ./scripts/build_onnxruntime_android.sh
    @./scripts/build_onnxruntime_android.sh --abi {{abi}} --ort-version v1.23.2 --api-level {{api-level}} --allow-root --zip --shared

# Downloads original model weights and converts them to ONNX format.
[working-directory: 'scripts/pyscripts']
@onnx-export model-dir:
    @echo "Exporting model to ONNX format in directory: {{model-dir}}"
    @uv run python onnx_export.py {{model-dir}}

[working-directory: '.']
@onnx-download-runtime abi="arm64-v8a" api-level="27" output-dir="onnx_runtimes":
    @echo "Downloading ONNX Runtime for Android..."
    @chmod +x ./scripts/download_onnxruntime_android.sh
    @./scripts/download_onnxruntime_android.sh {{abi}} {{api-level}} {{output-dir}}
