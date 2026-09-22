package com.konrad.nospam

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun BlockedNumbersScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val dao = remember { AppDatabase.getInstance(context).spamNumberDao() }
    val entries by dao.observeAll().collectAsState(initial = emptyList())

    var newNumber by remember { mutableStateOf("") }

    Column(modifier = modifier.fillMaxSize().padding(24.dp)) {
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            OutlinedTextField(
                value = newNumber,
                onValueChange = { newNumber = it },
                label = { Text("Aggiungi numero") },
                modifier = Modifier.weight(1f),
            )
            Button(
                onClick = {
                    val number = newNumber.trim()
                    if (number.isNotEmpty()) {
                        scope.launch {
                            PersonalBlocklist.add(context, number)
                            newNumber = ""
                        }
                    }
                },
            ) {
                Text("Aggiungi")
            }
        }

        Text(
            text = "Numeri bloccati (${entries.size})",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(top = 16.dp, bottom = 8.dp),
        )

        LazyColumn(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            items(entries, key = { it.phoneNumber }) { entry ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(entry.phoneNumber)
                        Text(
                            text = if (entry.source == NumberSource.COMMUNITY) {
                                "Community · ${entry.category}"
                            } else {
                                "Personale"
                            },
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                    if (entry.source == NumberSource.PERSONAL) {
                        TextButton(onClick = {
                            scope.launch { PersonalBlocklist.remove(context, entry.phoneNumber) }
                        }) {
                            Text("Rimuovi")
                        }
                    }
                }
                HorizontalDivider()
            }
        }
    }
}
