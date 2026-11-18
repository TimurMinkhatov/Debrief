//
//  DebriefSchema.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 02/10/2026.
//

import SwiftData

public enum DebriefSchema {
    public static let models: [any PersistentModel.Type] = [UserRecord.self, RunRecord.self]
}
