# Modified based on https://github.com/yuniko-software/bge-m3-onnx/blob/main/bge-m3-to-onnx.ipynb

import os
import sys
from pathlib import Path

import onnx
import torch
import torch.nn as nn

from FlagEmbedding.inference.embedder.encoder_only.m3 import M3Embedder


class ONNX_Wrapper(nn.Module):
    """Wrapper class to make BGE-M3 compatible with ONNX export"""
    def __init__(self, m3_embedder):
        super().__init__()
        self.m3_model = m3_embedder.model

    def forward(self, input_ids, attention_mask):
        outputs = self.m3_model({
            'input_ids': input_ids,
            'attention_mask': attention_mask
        },
        return_dense=True,
        return_sparse=False,
        return_colbert_vecs=False)

        return (outputs['dense_vecs'], )
    
    def export(self, output_path="model.onnx"):
        """Export BGE-M3 model to ONNX format"""
        output_path = Path(output_path)
        self.m3_model.eval()

        # Create dummy input
        dummy_input_ids = torch.randint(0, 1000, (1, 512), dtype=torch.long)
        dummy_attention_mask = torch.ones(1, 512, dtype=torch.long)

        print("Exporting model to ONNX...")

        torch.onnx.export(
            self,
            (dummy_input_ids, dummy_attention_mask),
            output_path,
            input_names=['input_ids', 'attention_mask'],
            output_names=['dense_embeddings'],
            dynamic_axes={
                'input_ids': {0: 'batch_size', 1: 'sequence_length'},
                'attention_mask': {0: 'batch_size', 1: 'sequence_length'},
                'dense_embeddings': {0: 'batch_size'},
            },
            opset_version=20,
            export_params=True
        )

        print(f"Model exported to: {output_path}")
        
        traced_model = onnx.load(output_path)

        data_filename = output_path.with_suffix(".onnx_data")
        onnx.save_model(
            traced_model,
            output_path,
            save_as_external_data=True,
            all_tensors_to_one_file=True,
            location=data_filename.name
        )

        # Delete the model.onnx.data file as it is not needed
        delete_file = Path(output_path).with_suffix(".onnx.data")
        if delete_file.exists():
            delete_file.unlink()

        return output_path
    

if __name__ == "__main__":
    model_name="abdulmatinomotoso/bge-finetuned"
    embedder = M3Embedder(
        model_name_or_path=model_name,
        use_fp16=False,  # Use FP32 for ONNX export
        normalize_embeddings=True
    )
    wrapper = ONNX_Wrapper(embedder)
    output_dir = Path.cwd()
    if len(sys.argv) > 1:
        output_dir = output_dir / sys.argv[1]

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    output_path = output_dir / "model.onnx"
    wrapper.export(output_path=output_path)