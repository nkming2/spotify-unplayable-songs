package com.nkming.spotify_removed_tracks

import android.app.Activity
import android.content.Intent
import com.spotify.sdk.android.auth.AuthorizationClient
import com.spotify.sdk.android.auth.AuthorizationRequest
import com.spotify.sdk.android.auth.AuthorizationResponse

class Authenticator(activity: Activity,
		onSuccess: ((response: AuthorizationResponse) -> Unit)? = null,
		onFailure: ((response: AuthorizationResponse) -> Unit)? = null,
		onCancel: ((response: AuthorizationResponse) -> Unit)? = null)
{
	companion object
	{
		private val LOG_TAG = Authenticator::class.java.canonicalName
		private const val REQUEST_CODE = 1
	}

	operator fun invoke()
	{
		val builder = AuthorizationRequest.Builder(BuildConfig.SPOTIFY_CLIENT_ID,
				AuthorizationResponse.Type.TOKEN,
				BuildConfig.SPOTIFY_AUTH_REDIRECT_URI)
		builder.setScopes(arrayOf("user-library-read",
				"user-library-modify",
				"playlist-read-private",
				"playlist-modify-public",
				"playlist-modify-private"))
		val req = builder.build()
		AuthorizationClient.openLoginActivity(_activity, REQUEST_CODE, req)
	}

	fun onActivityResult(requestCode: Int, resultCode: Int,
			data: Intent?)
	{
		if (requestCode == REQUEST_CODE)
		{
			val response = AuthorizationClient.getResponse(resultCode, data)
			when (response.type)
			{
				// Response was successful and contains auth token
				AuthorizationResponse.Type.TOKEN -> onSuccess(response)

				// Auth flow returned an error
				AuthorizationResponse.Type.ERROR -> onFailure(response)

				// Most likely auth flow was cancelled
				else -> onCancel(response)
			}
		}
	}

	val onSuccess = onSuccess
	val onFailure = onFailure
	val onCancel = onCancel

	private fun onSuccess(response: AuthorizationResponse)
	{
		Log.d("$LOG_TAG.onSuccess",
				"Token: ${response.accessToken}, Expire in: ${response.expiresIn}")
		onSuccess?.invoke(response)
	}

	private fun onFailure(response: AuthorizationResponse)
	{
		Log.w("$LOG_TAG.onFailure",
				"Code: ${response.code}, error: ${response.error}")
		onFailure?.invoke(response)
	}

	private fun onCancel(response: AuthorizationResponse)
	{
		Log.i("$LOG_TAG.onCancel", "onCancel()")
		onCancel?.invoke(response)
	}

	private val _activity = activity
}
