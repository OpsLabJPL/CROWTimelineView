//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation

public class TimeSelection: ObservableObject {
    @Published public var selectedTime: Date?

    public init(selectedTime: Date? = nil) {
        self.selectedTime = selectedTime
    }
}
