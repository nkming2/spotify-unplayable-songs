package com.nkming.spotify_removed_tracks

import android.content.Intent
import android.widget.Toast
import androidx.annotation.NonNull;
import com.spotify.sdk.android.auth.AuthorizationResponse
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity()
{
	companion object
	{
		const val API_AUTHER_CHANNEL = "com.nkming.spotify_removed_tracks/ApiAuther"
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int,
			data: Intent?)
	{
		super.onActivityResult(requestCode, resultCode, data)
		_authenticator.onActivityResult(requestCode, resultCode, data)
	}

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine)
	{
		super.configureFlutterEngine(flutterEngine)
		_flutter.setMethodCallHandler { call, result ->
			run {
				if (call.method == "auth")
				{
					auth(result)
				}
				else
				{
					result.notImplemented()
				}
			}
		}
	}

	private fun auth(result: MethodChannel.Result)
	{
		synchronized(_results) {
			_results.add(result)
		}
		_authenticator()
	}

	private fun onSuccess(response: AuthorizationResponse)
	{
		synchronized(_results) {
			for (r in _results) {
				r.success(mapOf(
					"accessToken" to response.accessToken,
					"expiresIn" to response.expiresIn
				))
			}
		}
	}

	private fun onFailure(response: AuthorizationResponse)
	{
		Toast.makeText(context, getString(R.string.auth_failed, response.error),
				Toast.LENGTH_LONG).show()
		synchronized(_results) {
			for (r in _results) {
				r.error("-1", null, null)
			}
		}
	}

	private fun onCancel(response: AuthorizationResponse)
	{
		Toast.makeText(context, R.string.auth_cancelled, Toast.LENGTH_LONG).show()
		synchronized(_results) {
			for (r in _results) {
				r.error("-1", null, null)
			}
		}
	}

	private val _flutter by lazy {
		MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger,
				API_AUTHER_CHANNEL)
	}

	private val _authenticator by lazy {
		Authenticator(this, onSuccess = ::onSuccess, onFailure = ::onFailure,
				onCancel = ::onCancel)
	}

	private val _results = arrayListOf<MethodChannel.Result>()
}
