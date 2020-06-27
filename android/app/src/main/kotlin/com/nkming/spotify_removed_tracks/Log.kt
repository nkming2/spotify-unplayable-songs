package com.nkming.spotify_removed_tracks

interface Log
{
	companion object
	{
		// always show
		fun wtf(tag: String, msg: String) = android.util.Log.wtf(tag, msg)

		// always show
		fun wtf(tag: String, msg: String, tr: Throwable) = android.util.Log.wtf(
				tag, msg, tr)

		// always show
		fun e(tag: String, msg: String) = android.util.Log.e(tag, msg)

		// always show
		fun e(tag: String, msg: String, tr: Throwable) = android.util.Log.e(
				tag, msg, tr)

		// always show
		fun w(tag: String, msg: String) = android.util.Log.w(tag, msg)

		// always show
		fun w(tag: String, msg: String, tr: Throwable) = android.util.Log.w(
				tag, msg, tr)

		fun i(tag: String, msg: String) = if (isShowInfo)
				android.util.Log.i(tag, msg) else -1

		fun i(tag: String, msg: String, tr: Throwable) = if (isShowInfo)
				android.util.Log.i(tag, msg, tr) else -1

		fun d(tag: String, msg: String) = if (isShowDebug)
				android.util.Log.d(tag, msg) else -1

		fun d(tag: String, msg: String, tr: Throwable) = if (isShowDebug)
				android.util.Log.d(tag, msg, tr) else -1

		fun v(tag: String, msg: String) = if (isShowVerbose)
				android.util.Log.v(tag, msg) else -1

		fun v(tag: String, msg: String, tr: Throwable) = if (isShowVerbose)
				android.util.Log.v(tag, msg, tr) else -1

		var isShowInfo = true
		var isShowDebug = false
		var isShowVerbose = false
	}
}
