//
//  BoraApp.swift
//  Bora
//
//  Created by Rodrigo Galeano on 12/09/26.
//

import SwiftUI

@main
struct BoraApp: App {
    var body: some Scene {
        WindowGroup {
            RootCoordinatorView(dependencies: .live)
        }
    }
}
