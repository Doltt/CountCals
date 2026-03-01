//
//  PaceWidgetsBundle.swift
//  PaceWidgets
//
//  Created by Doltt on 2026/1/26.
//

import WidgetKit
import SwiftUI

@main
struct PaceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PaceWidgets()
        PaceWidgetsControl()
        PaceWidgetsLiveActivity()
    }
}
