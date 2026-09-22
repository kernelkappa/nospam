package com.konrad.nospam

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    Scaffold { innerPadding ->
                        ReportScreen(modifier = Modifier.padding(innerPadding))
                    }
                }
            }
        }
    }
}

@Composable
fun ReportScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var phoneNumber by remember { mutableStateOf("") }
    var category by remember { mutableStateOf(ReportCategory.SPAM) }
    var statusMessage by remember { mutableStateOf<String?>(null) }
    var isSubmitting by remember { mutableStateOf(false) }

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
    }
}
