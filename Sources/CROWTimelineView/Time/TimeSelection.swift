//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import SwiftUI

@Observable 
public class TimeSelection {
    public var selectedTime: Date?

    public init(selectedTime: Date? = nil) {
        self.selectedTime = selectedTime
    }
}
