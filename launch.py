'''Add the current directory to the python path and launch the dicom_repair.py script.'''

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.resolve()))

from dicom_repair import main

if __name__ == '__main__':
    main()
