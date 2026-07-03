package com.maurimesh.routing

import java.util.concurrent.ConcurrentHashMap

data class MeshRoute(
    val destination: String,
    val nextHop: String,
    val score: Double,
    val updatedAt: Long = System.currentTimeMillis(),
    val hopCount: Int = 1,
    val transport: String = "BLE"
)

class MeshRouteTable {
    private val routes = ConcurrentHashMap<String, MeshRoute>()

    fun upsert(route: MeshRoute) {
        val existing = routes[route.destination]

        if (existing == null || route.score >= existing.score) {
            routes[route.destination] = route
        }
    }

    fun update(
        destination: String,
        nextHop: String,
        score: Double,
        hopCount: Int = 1,
        transport: String = "BLE"
    ) {
        upsert(
            MeshRoute(
                destination = destination,
                nextHop = nextHop,
                score = score,
                hopCount = hopCount,
                transport = transport
            )
        )
    }

    fun bestRoute(destination: String): MeshRoute? {
        return routes[destination]
    }

    fun nextHop(destination: String): String? {
        return routes[destination]?.nextHop
    }

    fun remove(destination: String) {
        routes.remove(destination)
    }

    fun all(): List<MeshRoute> {
        return routes.values
            .sortedWith(
                compareByDescending<MeshRoute> { it.score }
                    .thenBy { it.hopCount }
                    .thenByDescending { it.updatedAt }
            )
    }

    fun size(): Int {
        return routes.size
    }

    fun clear() {
        routes.clear()
    }
}
