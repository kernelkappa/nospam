package com.konrad.nospam

import android.Manifest
import android.app.role.RoleManager
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.LaunchedEffect
import androidx.core.content.ContextCompat
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.TextButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

private enum class NospamScreen { MAIN, BLOCKED_NUMBERS, CREDITS, SETTINGS }

class MainActivity : ComponentActivity() {
    @OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        ConsentManager.start(this)
        setContent {
            val context = LocalContext.current
            val themeMode = rememberThemeMode(context)
            androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode(
                when (themeMode.value) {
                    ThemeMode.LIGHT -> androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_NO
                    ThemeMode.DARK -> androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_YES
                    ThemeMode.SYSTEM -> androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
                },
            )

            MaterialTheme(
                colorScheme = if (androidx.compose.foundation.isSystemInDarkTheme()) {
                    androidx.compose.material3.darkColorScheme()
                } else {
                    androidx.compose.material3.lightColorScheme()
                },
            ) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    var updateRequired by remember { mutableStateOf(false) }
                    LaunchedEffect(Unit) {
                        updateRequired = UpdateGate.isUpdateRequired(context)
                    }

                    if (updateRequired) {
                        UpdateRequiredScreen()
                        return@Surface
                    }

                    var screen by remember { mutableStateOf(NospamScreen.MAIN) }

                    Scaffold(
                        topBar = {
                            TopAppBar(
                                title = {
                                    Text(
                                        when (screen) {
                                            NospamScreen.MAIN -> stringResource(R.string.app_name)
                                            NospamScreen.BLOCKED_NUMBERS -> stringResource(R.string.blocked_numbers_title)
                                            NospamScreen.CREDITS -> stringResource(R.string.credits_title)
                                            NospamScreen.SETTINGS -> stringResource(R.string.settings_title)
                                        },
                                    )
                                },
                                navigationIcon = {
                                    if (screen == NospamScreen.CREDITS) {
                                        TextButton(onClick = { screen = NospamScreen.SETTINGS }) {
                                            Text(stringResource(R.string.nav_back))
                                        }
                                    } else if (screen != NospamScreen.MAIN) {
                                        TextButton(onClick = { screen = NospamScreen.MAIN }) {
                                            Text(stringResource(R.string.nav_back))
                                        }
                                    }
                                },
                                actions = {
                                    if (screen == NospamScreen.MAIN) {
                                        IconButton(onClick = { screen = NospamScreen.SETTINGS }) {
                                            Icon(Icons.Default.Settings, contentDescription = stringResource(R.string.settings_title))
                                        }
                                        TextButton(onClick = { screen = NospamScreen.BLOCKED_NUMBERS }) {
                                            Text(stringResource(R.string.blocked_numbers_title))
                                        }
                                    }
                                },
                            )
                        },
                    ) { innerPadding ->
                        when (screen) {
                            NospamScreen.MAIN -> MainScreen(modifier = Modifier.padding(innerPadding))
                            NospamScreen.BLOCKED_NUMBERS -> BlockedNumbersScreen(modifier = Modifier.padding(innerPadding))
                            NospamScreen.CREDITS -> CreditsScreen(modifier = Modifier.padding(innerPadding))
                            NospamScreen.SETTINGS -> SettingsScreen(
                                themeMode = themeMode,
                                onOpenCredits = { screen = NospamScreen.CREDITS },
                                modifier = Modifier.padding(innerPadding),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MainScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current

    var phoneNumber by remember { mutableStateOf("") }
    var category by remember { mutableStateOf(ReportCategory.SPAM) }
    var statusMessage by remember { mutableStateOf<String?>(null) }
    var isSubmitting by remember { mutableStateOf(false) }

    var isSyncing by remember { mutableStateOf(false) }
    var syncMessage by remember { mutableStateOf<String?>(null) }
    var isDatabaseStale by remember { mutableStateOf(SpamDatabaseSync.isStale(context)) }

    val roleManager = remember { context.getSystemService(RoleManager::class.java) }
    var isCallScreeningRoleHeld by remember {
        mutableStateOf(roleManager?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true)
    }
    val roleRequestLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult(),
    ) {
        isCallScreeningRoleHeld = roleManager?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true
    }

    val prefs = remember { context.getSharedPreferences("nospam_prefs", android.content.Context.MODE_PRIVATE) }
    var showOnboarding by remember {
        mutableStateOf(!isCallScreeningRoleHeld && !prefs.getBoolean("onboarding_shown", false))
    }

    // Necessario dall'API 33 per mostrare l'avviso "possibile wangiri" quando
    // arriva una chiamata da un prefisso della watchlist.
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) {}
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    if (showOnboarding) {
        AlertDialog(
            onDismissRequest = {
                prefs.edit().putBoolean("onboarding_shown", true).apply()
                showOnboarding = false
            },
            title = { Text(stringResource(R.string.onboarding_title)) },
            text = { Text(stringResource(R.string.onboarding_message)) },
            confirmButton = {
                TextButton(onClick = {
                    prefs.edit().putBoolean("onboarding_shown", true).apply()
                    showOnboarding = false
                    roleManager?.let {
                        roleRequestLauncher.launch(it.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING))
                    }
                }) {
                    Text(stringResource(R.string.onboarding_activate))
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    prefs.edit().putBoolean("onboarding_shown", true).apply()
                    showOnboarding = false
                }) {
                    Text(stringResource(R.string.onboarding_later))
                }
            },
        )
    }

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .pointerInput(Unit) {
                    detectTapGestures(onTap = {
                        focusManager.clearFocus()
                        keyboardController?.hide()
                    })
                }
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(text = stringResource(R.string.app_name), style = MaterialTheme.typography.headlineLarge)

            OutlinedTextField(
                value = phoneNumber,
                onValueChange = { phoneNumber = it },
                label = { Text(stringResource(R.string.phone_number_placeholder)) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = {
                    focusManager.clearFocus()
                    keyboardController?.hide()
                }),
                modifier = Modifier.fillMaxWidth(),
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                ReportCategory.entries.forEach { option ->
                    FilterChip(
                        selected = category == option,
                        onClick = { category = option },
                        label = { Text(stringResource(option.labelRes)) },
                    )
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = {
                        isSubmitting = true
                        statusMessage = null
                        scope.launch {
                            try {
                                PersonalBlocklist.add(context, phoneNumber, category.apiValue)
                                statusMessage = context.getString(R.string.status_blocked_locally)
                                phoneNumber = ""
                            } catch (e: Exception) {
                                ErrorReporter.report(context, e, "blockOnly")
                                statusMessage = context.getString(R.string.status_error_prefix, UserFacingError.message(context, e))
                            }
                            isSubmitting = false
                        }
                    },
                    enabled = phoneNumber.isNotBlank() && !isSubmitting,
                ) {
    Text(stringResource(R.string.block_button))
                }

                Button(
                    onClick = {
                        isSubmitting = true
                        statusMessage = null
                        scope.launch {
                            try {
                                val normalized = PersonalBlocklist.normalize(phoneNumber)
                                PersonalBlocklist.add(context, phoneNumber, category.apiValue)
                                ReportService.submit(context, normalized, category)
                                statusMessage = context.getString(R.string.status_blocked_and_reported)
                            } catch (e: Exception) {
                                ErrorReporter.report(context, e, "blockAndReport")
                                statusMessage = context.getString(R.string.status_report_failed_prefix, UserFacingError.message(context, e))
                            }
                            phoneNumber = ""
                            isSubmitting = false
                        }
                    },
                    enabled = phoneNumber.isNotBlank() && !isSubmitting,
                ) {
                    Text(if (isSubmitting) stringResource(R.string.sending) else stringResource(R.string.block_and_report_button))
                }
            }

            statusMessage?.let { Text(text = it) }

            HorizontalDivider()

            Text(
                text = if (isCallScreeningRoleHeld) {
                    stringResource(R.string.call_blocking_active)
                } else {
                    stringResource(R.string.call_blocking_inactive)
                },
            )

            if (!isCallScreeningRoleHeld && roleManager?.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) == true) {
                Button(onClick = {
                    roleRequestLauncher.launch(roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING))
                }) {
                    Text(stringResource(R.string.become_default_app))
                }
            }

            Button(
                onClick = {
                    isSyncing = true
                    syncMessage = null
                    scope.launch {
                        try {
                            SpamDatabaseSync.sync(context)
                            syncMessage = context.getString(R.string.sync_success)
                        } catch (e: Exception) {
                            ErrorReporter.report(context, e, "syncDatabase")
                            syncMessage = context.getString(R.string.status_error_prefix, UserFacingError.message(context, e))
                        }
                        isSyncing = false
                        isDatabaseStale = SpamDatabaseSync.isStale(context)
                    }
                },
                enabled = !isSyncing,
            ) {
                Text(if (isSyncing) stringResource(R.string.sync_updating) else stringResource(R.string.sync_button))
            }

            if (isDatabaseStale) {
                Text(text = stringResource(R.string.sync_stale_hint), color = Color(0xFFE65100))
            }

            syncMessage?.let { Text(text = it) }
        }
        AdBanner()
    }
}
