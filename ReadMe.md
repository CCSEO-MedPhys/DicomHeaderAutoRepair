# DICOM Import Repair

This package provides scripts for repairing DICOM headers when errors are
encountered importing into Eclipse.

## Requirements

### Required Packages

- pydicom=2.3.1
- PySimpleGUI=4.60.4
- Python>=3.9.13

### Recommended DEV Packages

(_Used to run the included Jupyter Notebooks_)

- pandas
- xlwings
- jupyterlab

## Install

Recommended: create and activate a virtual environment before installing dependencies.

Runtime only:

```bash
python -m pip install -r requirements.txt
```

Development and notebooks:

```bash
python -m pip install -r requirements-dev.txt
```

## Path configuration

The script will search for initial input and output folders in the dicom_repair_config.toml file.
The supplied paths can be absolute or relative to the location of the script.
If the input_path folder does not exist, the script will raise an error.
If the output_path folder does not exist, the script will create it.

## Source Files

- dicom_repair_tools
Key Functions:
  - scan_dicom_images
  - count_repairs
  - perform_repairs

- dicom_repair_functions
Key Functions:
  - REPAIR_METHODS

- dicom_repair_gui
Key Functions:
  - make_window
  - get_file_paths
  - status_output
  - wait_for_acknowledgement
