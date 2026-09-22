package com.konrad.nospam

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

private enum class SourceFilter(val label: String) {
    ALL("Tutti"),
    PERSONAL("Personali"),
}

@Composable
fun BlockedNumbersScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val dao = remember { AppDatabase.getInstance(context).spamNumberDao() }
    val allEntries by dao.observeAll().collectAsState(initial = emptyList())

    var searchText by remember { mutableStateOf("") }
    var sourceFilter by remember { mutableStateOf(SourceFilter.ALL) }

    val entries = allEntries
        .filter { sourceFilter == SourceFilter.ALL || it.source == NumberSource.PERSONAL }
        .filter { searchText.isBlank() || it.phoneNumber.contains(searchText) }

    Column(modifier = modifier.fillMaxSize().padding(24.dp)) {
        OutlinedTextField(
            value = searchText,
            onValueChange = { searchText = it },
            label = { Text("Cerca numero (es. 0691 o +3933...)") },
            modifier = Modifier.fillMaxWidth(),
        )

        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth().padding(top = 12.dp)) {
            SourceFilter.entries.forEachIndexed { index, filter ->
                SegmentedButton(
                    selected = sourceFilter == filter,
                    onClick = { sourceFilter = filter },
                    shape = SegmentedButtonDefaults.itemShape(index = index, count = SourceFilter.entries.size),
                ) {
                    Text(filter.label)
                }
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
                    verticalAlignment = Alignment.CenterVertically,
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
                            Text("Sblocca")
                        }
                    }
                }
                HorizontalDivider()
            }
        }
    }
}
