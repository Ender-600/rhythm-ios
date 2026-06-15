//
//  SupabaseConfig.swift
//  Rhythm
//
//  Created by 刘柏宇 on 1/8/26.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://gcxxkvvbbvpiaquiqfwi.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjeHhrdnZiYnZwaWFxdWlxZndpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3NzMzNTIsImV4cCI6MjA4MzM0OTM1Mn0.96Qu4gb18F2LnIp2eYTdmgpZRyfTyxefptTv6ZeeVA4"
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}
