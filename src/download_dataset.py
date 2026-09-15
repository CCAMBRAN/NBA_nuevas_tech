from pathlib import Path

import kagglehub


DATASET_HANDLE = "wyattowalsh/basketball"
PROJECT_ROOT = Path(__file__).resolve().parent.parent
CACHE_DIR = PROJECT_ROOT / "data" / "kaggle" / ".cache"


def download_dataset() -> None:
    """Download the complete Kaggle dataset into the mounted project data folder."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    dataset_path = kagglehub.dataset_download(
        DATASET_HANDLE,
        output_dir=str(CACHE_DIR),
    )
    print(f"Dataset downloaded to: {dataset_path}")


if __name__ == "__main__":
    download_dataset()