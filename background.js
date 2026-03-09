chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'highlightText',
    title: 'Highlight Text',
    contexts: ['selection']
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'highlightText') {
    chrome.tabs.sendMessage(tab.id, { action: 'highlight' }, (response) => {
      if (!response.success) {
        console.error('Highlight failed:', response.error);
      }
    });
  }
});