import ExternalLib
import WITMarker

@WIT
public func relabel(_ ext: External) -> External {
    External(label: ext.label + "!")
}
