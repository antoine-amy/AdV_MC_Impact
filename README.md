<table align="center"><tr><td align="center" width="9999">

# Auxiliary Mode Cleaner tests with OSCAR
## AMC development for the Virgo interferometer

</td></tr></table>

----------------------------------------------------------------------------------------------------------------------------------------------------------------

## Folder structure:

    My Directory
    │  
    │ AdV_n04_demod_circ.m           # Get the demodulated signals of the circulating field
    │ AdV_n04_fields.m               # Plot and save the fields
    │ AdV_n04_gains.m                # Get the gains of the recycling cavities
    │ AdV_n04_signals.m              # Get the PDs & quads signals
    │ AdV_n04.m                      # Avanced Virgo n04 basic file coming from the OSCAR [fft-playground](https://git.ligo.org/virgo/osd/fft-playground/-/tree/master)
    ├── Classes                      # OSCAR package classes
    └── Results                      # Folder containing the results of the OSCAR simulations (mainly figures)

----------------------------------------------------------------------------------------------------------------------------------------------------------------

## How to use:

Open the main matlab files with the OSCAR classes folder in the same directory.