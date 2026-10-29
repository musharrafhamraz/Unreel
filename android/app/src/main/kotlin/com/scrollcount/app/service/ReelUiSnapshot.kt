package com.scrollcount.app.service

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo

/** A bounded walk that retains semantic containers even when their children have no IDs. */
object ReelUiSnapshot {
    fun capture(root: AccessibilityNodeInfo): List<ReelUiNode> {
        val result = mutableListOf<ReelUiNode>()
        val viewport = Rect().also(root::getBoundsInScreen)
        var budget = 2500
        fun walk(node: AccessibilityNodeInfo, depth: Int, ids: List<String>, labels: List<String>) {
            if (depth > 64 || budget-- <= 0) return
            val id = node.viewIdResourceName.orEmpty().substringAfter(":id/")
            val label = ReelIdentity.normalize(node.text?.toString()?.takeIf { it.isNotBlank() }
                ?: node.contentDescription?.toString().orEmpty())
            val bounds = Rect().also(node::getBoundsInScreen)
            val visible = node.isVisibleToUser && Rect.intersects(viewport, bounds)
            if (visible) result.add(ReelUiNode(id, label, ids, labels, node.isSelected,
                !node.text.isNullOrBlank(), (bounds.right - viewport.left).toFloat() / viewport.width().coerceAtLeast(1),
                node.className?.toString().orEmpty()))
            // Some layout wrappers report invisible while their children are visible.
            val nextIds = if (id.isBlank()) ids else ids + id
            val nextLabels = if (visible && label.isNotBlank()) labels + label else labels
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                try { walk(child, depth + 1, nextIds, nextLabels) } finally { child.recycle() }
            }
        }
        walk(root, 0, emptyList(), emptyList())
        return result
    }
}
