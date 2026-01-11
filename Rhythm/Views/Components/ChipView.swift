//
//  ChipView.swift
//  Rhythm
//
//  Reusable chip component for tags and signals
//

import SwiftUI

struct ChipView: View {
    let text: String
    var icon: String?
    var style: ChipStyle = .default
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    
    enum ChipStyle {
        case `default`
        case signal
        case tag
        case priority(TaskPriority)
        
        var backgroundColor: Color {
            switch self {
            case .default:
                return .rhythmChipBackground
            case .signal:
                return .rhythmAmber.opacity(0.2)
            case .tag:
                return .rhythmSage.opacity(0.2)
            case .priority(let priority):
                return priority.color.opacity(0.2)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .default:
                return .rhythmTextPrimary
            case .signal:
                return .rhythmAmber
            case .tag:
                return .rhythmSage
            case .priority(let priority):
                return priority.color
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isSelected ? style.foregroundColor.opacity(0.3) : style.backgroundColor
        )
        .foregroundColor(style.foregroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected ? style.foregroundColor : Color.clear,
                    lineWidth: 1.5
                )
        )
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let name: String
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    
    var body: some View {
        ChipView(
            text: "#\(name)",
            style: .tag,
            isSelected: isSelected,
            onTap: onTap
        )
    }
}

// MARK: - Priority Chip

struct PriorityChip: View {
    let priority: TaskPriority
    var isCompact: Bool = false
    
    var body: some View {
        ChipView(
            text: isCompact ? priority.rawValue.capitalized : priority.displayName,
            icon: "flag.fill",
            style: .priority(priority)
        )
    }
}

// MARK: - Chip Flow Layout

struct ChipFlowLayout: View {
    let chips: [String]
    var selectedChips: Set<String> = []
    var onChipTap: ((String) -> Void)?
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(chips, id: \.self) { chip in
                TagChip(
                    name: chip,
                    isSelected: selectedChips.contains(chip)
                ) {
                    onChipTap?(chip)
                }
            }
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack {
            ChipView(text: "tonight", icon: "clock", style: .signal)
            ChipView(text: "first do", icon: "list.number", style: .signal)
        }
        
        HStack {
            TagChip(name: "work")
            TagChip(name: "email", isSelected: true)
        }
        
        HStack {
            PriorityChip(priority: .urgent)
            PriorityChip(priority: .normal)
            PriorityChip(priority: .low)
        }
        
        ChipFlowLayout(
            chips: ["work", "email", "meeting", "urgent", "home"],
            selectedChips: ["work", "email"]
        )
        .padding()
    }
    .padding()
}

