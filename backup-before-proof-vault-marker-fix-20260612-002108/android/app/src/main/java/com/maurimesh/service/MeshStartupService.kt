package com.maurimesh.service

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.maurimesh.mesh.MeshForegroundService

class MeshStartupService {
    companion object {
        private const val TAG = "MauriMeshStartup"

        fun start(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = MeshForegroundService.ACTION_START
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                Log.i(TAG, "Mesh foreground service start requested")
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to start mesh foreground service", t)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = MeshForegroundService.ACTION_STOP
            }

            try {
                context.startService(intent)
                Log.i(TAG, "Mesh foreground service stop requested")
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to stop mesh foreground service", t)
            }
        }

        fun restart(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = MeshForegroundService.ACTION_RESTART
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                Log.i(TAG, "Mesh foreground service restart requested")
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to restart mesh foreground service", t)
            }
        }
    }
}
