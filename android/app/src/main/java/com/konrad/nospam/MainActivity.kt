package com.konrad.nospam

import android.app.role.RoleManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.TextButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

private enum class NospamScreen { MAIN, BLOCKED_NUMBERS }

class MainActivity : ComponentActivity() {
    @OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    var screen by remember { mutableStateOf(NospamScreen.MAIN) }

                    Scaffold(
                        topBar = {
                            TopAppBar(
                                title = { Text(if (screen == NospamScreen.MAIN) "NoSpam" else "Numeri bloccati") },
                                navigationIcon = {
                                    if (screen == NospamScreen.BLOCKED_NUMBERS) {
                                        TextButton(onClick = { screen = NospamScreen.MAIN }) {
                                            Text("‹ Indietro")
                                        }
                                    }
                                },
                                actions = {
                                    if (screen == NospamScreen.MAIN) {
                                        TextButton(onClick = { screen = NospamScreen.BLOCKED_NUMBERS }) {
                                            Text("Numeri bloccati")
                                        }
                                    }
                                },
                            )
                        },
                    ) { innerPadding ->
                        when (screen) {
                            NospamScreen.MAIN -> MainScreen(modifier = Modifier.padding(innerPadding))
                            NospamScreen.BLOCKED_NUMBERS -> BlockedNumbersScreen(modifier = Modifier.padding(innerPadding))
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

    var phoneNumber by remember { mutableStateOf("") }
    var category by remember { mutableStateOf(ReportCategory.SPAM) }
    var statusMessage by remember { mutableStateOf<String?>(null) }
    var isSubmitting by remember { mutableStateOf(false) }

    var isSyncing by remember { mutableStateOf(false) }
    var syncMessage by remember { mutableStateOf<String?>(null) }

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

    if (showOnboarding) {
        AlertDialog(
            onDismissRequest = {
                prefs.edit().putBoolean("onboarding_shown", true).apply()
                showOnboarding = false
            },
            title = { Text("Blocca le chiamate spam") },
            text = {
                Text(
                    "Per bloccare automaticamente le chiamate spam, NoSpam deve diventare " +
                        "l'app di blocco e identificazione chiamate del telefono. Puoi cambiarla " +
                        "in qualsiasi momento dalle impostazioni di sistema.",
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    prefs.edit().putBoolean("onboarding_shown", true).apply()
                    showOnboarding = false
                    roleManager?.let {
                        roleRequestLauncher.launch(it.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING))
                    }
                }) {
                    Text("Attiva ora")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    prefs.edit().putBoolean("onboarding_shown", true).apply()
                    showOnboarding = false
                }) {
                    Text("Più tardi")
                }
            },
        )
    }

    Column(
        modifier = modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(text = "NoSpam", style = MaterialTheme.typography.headlineLarge)

        OutlinedTextField(
            value = phoneNumber,
            onValueChange = { phoneNumber = it },
            label = { Text("Numero (es. +393331234567)") },
            modifier = Modifier.fillMaxWidth(),
        )

        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            ReportCategory.entries.forEachIndexed { index, option ->
                SegmentedButton(
                    selected = category == option,
                    onClick = { category = option },
                    shape = SegmentedButtonDefaults.itemShape(index = index, count = ReportCategory.entries.size),
                ) {
                    Text(option.apiValue)
                }
            }
        }

        Button(
            onClick = {
                isSubmitting = true
                statusMessage = null
                scope.launch {
                    try {
                        ReportService.submit(context, phoneNumber, category)
                        statusMessage = "Segnalazione inviata."
                        phoneNumber = ""
                    } catch (e: Exception) {
                        statusMessage = "Errore: ${e.message}"
                    }
                    isSubmitting = false
                }
            },
            enabled = phoneNumber.isNotBlank() && !isSubmitting,
        ) {
            Text(if (isSubmitting) "Invio..." else "Segnala")
        }

        statusMessage?.let { Text(text = it) }

        HorizontalDivider()

        Text(
            text = if (isCallScreeningRoleHeld) {
                "Blocco chiamate attivo."
            } else {
                "NoSpam non è l'app di blocco chiamate predefinita."
            },
        )

        if (!isCallScreeningRoleHeld && roleManager?.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) == true) {
            Button(onClick = {
                roleRequestLauncher.launch(roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING))
            }) {
                Text("Diventa app predefinita")
            }
        }

        Button(
            onClick = {
                isSyncing = true
                syncMessage = null
                scope.launch {
                    try {
                        SpamDatabaseSync.sync(context)
                        syncMessage = "Database aggiornato."
                    } catch (e: Exception) {
                        syncMessage = "Errore: ${e.message}"
                    }
                    isSyncing = false
                }
            },
            enabled = !isSyncing,
        ) {
            Text(if (isSyncing) "Aggiornamento..." else "Aggiorna database spam")
        }

        syncMessage?.let { Text(text = it) }
    }
}
