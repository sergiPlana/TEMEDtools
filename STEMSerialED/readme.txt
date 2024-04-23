This scripts enables the fast and automated acquisition of ED patterns in STEM mode from manually selected position. This is thought for a type of serial crystallography experiment but using a TEM. It needs the 'FastADT_Storage' folder from the FastADT software as it requires the Python interface
with the microscope. The first lines of this DM script have to be modified to point to the path of this folder.

This is an implementation fully optimized for a JEOL F200 with an Gatan camera (ideally OneView) and a DigiScan scanning system. It also takes into account that the PyJEM package from JEOL to control the microscope is installed and configured in the same PC of Digital Micrograph.
