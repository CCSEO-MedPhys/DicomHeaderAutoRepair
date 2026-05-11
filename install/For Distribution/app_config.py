"""Load path configuration for DICOM repair scripts."""

from pathlib import Path
import tomllib


CONFIG_FILE = Path(__file__).with_name("dicom_repair_config.toml")


def _load_config() -> dict:
    """Read and parse the TOML configuration file."""
    try:
        with CONFIG_FILE.open("rb") as config_handle:
            return tomllib.load(config_handle)
    except FileNotFoundError as exc:
        raise RuntimeError(f"Missing config file: {CONFIG_FILE}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise RuntimeError(f"Invalid TOML in config file: {CONFIG_FILE}") from exc


def _get_required_path(config: dict, section: str, key: str) -> Path:
    """Get a required path value from a section and normalize relative paths."""
    section_data = config.get(section)
    if not isinstance(section_data, dict):
        raise RuntimeError(f"Missing section [{section}] in {CONFIG_FILE}")

    value = section_data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise RuntimeError(
            f"Missing or invalid '{key}' in section [{section}] of {CONFIG_FILE}"
        )

    parsed_path = Path(value).expanduser()
    if not parsed_path.is_absolute():
        parsed_path = CONFIG_FILE.parent / parsed_path
    return parsed_path


def get_main_default_paths() -> tuple[Path, Path]:
    """Return input and output default paths for the main app."""
    config = _load_config()
    input_path = _get_required_path(config, "main", "input_path")
    if not input_path.exists():
        raise RuntimeError(f"Input path does not exist: {input_path}")
    output_path = _get_required_path(config, "main", "output_path")
    if not output_path.exists():
        output_path.mkdir(parents=True, exist_ok=True)
    return input_path, output_path


def get_gui_test_paths() -> tuple[Path, Path]:
    """Return test input and output paths for GUI standalone testing."""
    config = _load_config()
    test_data_path = _get_required_path(config, "gui_test", "test_data_path")
    output_path = _get_required_path(config, "gui_test", "output_path")
    return test_data_path, output_path
