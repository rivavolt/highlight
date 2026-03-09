let highlights = [];

function isRangeOverlapping(range1, range2) {
  const rect1 = range1.getBoundingClientRect();
  const rect2 = range2.getBoundingClientRect();
  
  if (range1.commonAncestorContainer === range2.commonAncestorContainer) {
    const compare = range1.compareBoundaryPoints(Range.START_TO_END, range2);
    const compare2 = range2.compareBoundaryPoints(Range.START_TO_END, range1);
    return compare >= 0 && compare2 >= 0;
  }
  
  return false;
}

function createHighlight(range) {
  const id = Date.now().toString();
  const contents = range.extractContents();
  const span = document.createElement('span');
  span.className = 'text-highlight';
  span.dataset.highlightId = id;
  span.appendChild(contents);
  range.insertNode(span);
  
  highlights.push({
    id,
    element: span
  });
  
  return id;
}

function removeHighlight(highlightId) {
  const index = highlights.findIndex(h => h.id === highlightId);
  if (index === -1) return;
  
  const highlight = highlights[index];
  const parent = highlight.element.parentNode;
  
  while (highlight.element.firstChild) {
    parent.insertBefore(highlight.element.firstChild, highlight.element);
  }
  
  parent.removeChild(highlight.element);
  highlights.splice(index, 1);
  
  parent.normalize();
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'highlight') {
    const selection = window.getSelection();
    if (selection.rangeCount === 0 || selection.isCollapsed) {
      sendResponse({ success: false, error: 'No text selected' });
      return;
    }
    
    const range = selection.getRangeAt(0);
    
    for (const highlight of highlights) {
      const existingRange = document.createRange();
      existingRange.selectNode(highlight.element);
      
      if (isRangeOverlapping(range, existingRange)) {
        sendResponse({ success: false, error: 'Overlapping highlights not allowed' });
        return;
      }
    }
    
    const highlightId = createHighlight(range);
    selection.removeAllRanges();
    
    sendResponse({ success: true, highlightId });
  }
});

let deleteMode = false;
let selectedHighlight = null;

document.addEventListener('keydown', (e) => {
  if (e.key === 'Delete' || e.key === 'Backspace') {
    if (selectedHighlight) {
      removeHighlight(selectedHighlight);
      selectedHighlight = null;
      deleteMode = false;
      document.querySelectorAll('.highlight-selected').forEach(el => {
        el.classList.remove('highlight-selected');
      });
    }
  }
});

document.addEventListener('click', (e) => {
  if (e.target.classList.contains('text-highlight')) {
    if (selectedHighlight === e.target.dataset.highlightId) {
      e.target.classList.remove('highlight-selected');
      selectedHighlight = null;
    } else {
      document.querySelectorAll('.highlight-selected').forEach(el => {
        el.classList.remove('highlight-selected');
      });
      e.target.classList.add('highlight-selected');
      selectedHighlight = e.target.dataset.highlightId;
    }
  } else {
    document.querySelectorAll('.highlight-selected').forEach(el => {
      el.classList.remove('highlight-selected');
    });
    selectedHighlight = null;
  }
});