// Target: PikminWidgets
// Bundle entry point — registers all widgets and live activities for this extension.

import SwiftUI
import WidgetKit

@main
struct PikminWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MushroomWidget()
        MushroomLiveActivity()
    }
}
