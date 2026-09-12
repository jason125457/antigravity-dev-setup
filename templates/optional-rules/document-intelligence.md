---
trigger: model_decision
description: Local document processing hierarchy (Docling, MarkItDown, MinerU Local) for PDF, DOCX, PPTX, XLSX.
---

# Document Intelligence & Parsing Guidelines

1. **Local-Only Processing**:
   - All confidential files, network logs, internal IPs, and sensitive data must be processed 100% locally.
   - Never use third-party cloud document parsing APIs.

2. **Parser Selection Hierarchy**:
   - **Docling (Default)**: Primary structured parser for PDF, DOCX, PPTX, XLSX, and high-accuracy table reconstruction.
   - **MarkItDown (Fast Fallback)**: Rapid CLI extraction for plain text and simple Office conversions.
   - **MinerU Local (Visual Fallback)**: Heavy local pipeline mode for complex formulas, visual element cropping, and dense scanned documents.

3. **Cross-Validation**:
   - Critical numerical values in tables/charts must be cross-verified against original pages.
