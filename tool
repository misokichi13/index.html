<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>会議音声ハイライト要約ツール - Step3 Auto-Compress</title>
  <style>
    body {
      font-family: sans-serif;
      max-width: 900px;
      margin: 20px auto;
      padding: 0 20px;
      line-height: 1.6;
      color: #333;
    }
    .card {
      border: 1px solid #ccc;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
      background-color: #f9f9f9;
    }
    audio {
      width: 100%;
      margin-top: 10px;
    }
    input[type="password"] {
      width: 100%;
      padding: 8px;
      margin-top: 5px;
      box-sizing: border-box;
    }
    button.action-btn {
      background-color: #28a745;
      color: white;
      border: none;
      padding: 10px 20px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 1em;
      margin-top: 10px;
    }
    button.action-btn:disabled {
      background-color: #ccc;
      cursor: not-allowed;
    }
    .sub-btn {
      background-color: #6c757d;
      color: white;
      border: none;
      padding: 6px 12px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.9em;
      margin-right: 5px;
    }
    .sub-btn.active {
      background-color: #007bff;
    }
    .timestamp-btn {
      background-color: #007bff;
      color: white;
      border: none;
      padding: 4px 8px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.9em;
      margin-right: 10px;
      flex-shrink: 0;
    }
    .timestamp-btn:hover {
      background-color: #0056b3;
    }
    
    .transcript-scroll-area {
      max-height: 450px;
      overflow-y: auto;
      border: 1px solid #ddd;
      border-radius: 6px;
      background: #fff;
      padding: 10px;
    }

    .transcript-list {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    .transcript-list li {
      padding: 12px;
      border-bottom: 1px solid #eee;
      margin-bottom: 6px;
      display: flex;
      align-items: flex-start;
    }
    .transcript-list li:last-child {
      border-bottom: none;
    }

    .editable-text {
      flex-grow: 1;
      padding: 4px 8px;
      border: 1px solid transparent;
      border-radius: 4px;
      outline: none;
      transition: background 0.2s, border-color 0.2s;
    }
    .editable-text:hover {
      background-color: #f0f7ff;
      border-color: #b3d7ff;
    }
    .editable-text:focus {
      background-color: #fff;
      border-color: #80bdff;
      box-shadow: 0 0 0 0.2rem rgba(0,123,255,.25);
    }

    mark {
      background-color: #ffcccc;
      color: #d9534f;
      padding: 2px 4px;
      border-radius: 2px;
      font-weight: bold;
    }
    #summaryArea {
      background: #e9ecef;
      padding: 15px;
      border-radius: 6px;
      margin-bottom: 15px;
      white-space: pre-wrap;
      outline: none;
      border: 1px solid transparent;
    }
    #summaryArea:hover {
      border-color: #b3d7ff;
    }
    .toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10px;
      flex-wrap: wrap;
      gap: 10px;
    }
    #loading {
      display: none;
      color: #007bff;
      font-weight: bold;
      margin-top: 10px;
    }
    .hint-text {
      font-size: 0.85em;
      color: #666;
      margin-bottom: 8px;
    }
  </style>
</head>
<body>

  <h1>会議音声ハイライト要約ツール</h1>
  <p>Step3 Auto-Compress: ブラウザ内・音声軽量化（圧縮）機能搭載</p>

  <!-- 1. APIキー入力 -->
  <div class="card">
    <h3>1. Gemini APIキーの設定</h3>
    <input type="password" id="apiKeyInput" placeholder="APIキーを入力してください">
    <small style="color:#666;">※APIキーはブラウザ内でのみ使用されます。</small>
  </div>

  <!-- 2. 音声ファイル選択 & プレイヤー -->
  <div class="card">
    <h3>2. 音声ファイルを選択 (WAV / M4A / MP3 対応)</h3>
    <input type="file" id="audioFileInput" accept="audio/*">
    <br><br>
    <audio id="audioPlayer" controls></audio>
    <br><br>
    <button id="analyzeBtn" class="action-btn" onclick="analyzeAudio()" disabled>AI要約・文字起こしを実行（自動軽量化付き）</button>
    <div id="loading">処理中です...</div>
  </div>

  <!-- 3. 解析結果の表示エリア -->
  <div class="card" id="resultCard" style="display:none;">
    <h3>3. 会議要約サマリー（直接編集可能）</h3>
    <p class="hint-text">※要約テキストをクリックすると、その場で手動修正できます。</p>
    <div id="summaryArea" contenteditable="true"></div>

    <h3>4. 文字起こしリスト</h3>
    <p class="hint-text">※文字起こし文言をクリックすると、その場で直接キーボード入力で修正できます。</p>
    
    <div class="toolbar">
      <div>
        <button id="btnShowAll" class="sub-btn active" onclick="filterList('all')">すべて表示</button>
        <button id="btnShowHighlights" class="sub-btn" onclick="filterList('highlight')">補完箇所（赤色ハイライト）のみ表示</button>
      </div>
      <div>
        <button class="sub-btn" onclick="copyResults()">修正後の内容をコピー</button>
        <button class="sub-btn" onclick="downloadResults()">txtで保存</button>
      </div>
    </div>

    <!-- 内部スクロールコンテナ -->
    <div class="transcript-scroll-area">
      <ul id="transcriptContainer" class="transcript-list"></ul>
    </div>
  </div>

  <script>
    const MODEL_NAME = 'gemini-3.8-flash';

    const audioFileInput = document.getElementById('audioFileInput');
    const audioPlayer = document.getElementById('audioPlayer');
    const analyzeBtn = document.getElementById('analyzeBtn');
    const apiKeyInput = document.getElementById('apiKeyInput');
    const loading = document.getElementById('loading');
    const resultCard = document.getElementById('resultCard');
    const summaryArea = document.getElementById('summaryArea');
    const transcriptContainer = document.getElementById('transcriptContainer');

    let selectedFile = null;
    let fullResultData = null;

    audioFileInput.addEventListener('change', (event) => {
      selectedFile = event.target.files[0];
      if (selectedFile) {
        console.log('選択されたファイル:', selectedFile.name, 'Size:', (selectedFile.size / 1024 / 1024).toFixed(2) + 'MB');
        audioPlayer.src = URL.createObjectURL(selectedFile);
        analyzeBtn.disabled = false;
      }
    });

    function formatTime(seconds) {
      const m = Math.floor(seconds / 60).toString().padStart(2, '0');
      const s = Math.floor(seconds % 60).toString().padStart(2, '0');
      return `${m}:${s}`;
    }

    function seekTo(seconds) {
      if (!audioPlayer.src) return;
      audioPlayer.currentTime = seconds;
      audioPlayer.play();
    }

    // ブラウザ内で重い音声を直接軽量化（圧縮）する関数
    async function compressAudioIfNeeded(file) {
      // 20MB以下のファイルは圧縮不要としてそのまま返す
      if (file.size <= 20 * 1024 * 1024) {
        console.log('ファイルサイズが20MB以下のため圧縮なしで処理します。');
        return file;
      }

      loading.textContent = `重い音声（${(file.size / 1024 / 1024).toFixed(1)}MB）をブラウザ内で自動軽量化（圧縮）中...`;

      return new Promise(async (resolve, reject) => {
        try {
          const arrayBuffer = await file.arrayBuffer();
          const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
          const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);

          const dest = audioCtx.createMediaStreamDestination();
          const source = audioCtx.createBufferSource();
          source.buffer = audioBuffer;
          source.connect(dest);

          // ブラウザ対応のコーデックを選択（WebM OPUS 等）
          let mimeType = 'audio/webm;codecs=opus';
          if (!MediaRecorder.isTypeSupported(mimeType)) {
            mimeType = 'audio/webm';
          }

          const recorder = new MediaRecorder(dest.stream, {
            mimeType: mimeType,
            audioBitsPerSecond: 32000 // 低ビットレートで大幅圧縮
          });

          const chunks = [];
          recorder.ondataavailable = e => chunks.push(e.data);
          recorder.onstop = () => {
            const blob = new Blob(chunks, { type: mimeType });
            const compressedFile = new File([blob], file.name.replace(/\.[^/.]+$/, "") + ".webm", { type: mimeType });
            console.log(`圧縮完了: 元 ${(file.size / 1024 / 1024).toFixed(1)}MB -> 圧縮後 ${(compressedFile.size / 1024 / 1024).toFixed(1)}MB`);
            audioCtx.close();
            resolve(compressedFile);
          };

          recorder.start();
          source.start(0);

          // 処理加速のシミュレーション完了監視
          source.onended = () => {
            recorder.stop();
          };

        } catch (err) {
          console.warn('自動圧縮処理に失敗したため、元ファイルで送信を試みます:', err);
          resolve(file); // エラー時は元ファイルへフォールバック
        }
      });
    }

    function getCorrectMimeType(file) {
      let mime = file.type;
      if (!mime || mime === '') {
        const ext = file.name.split('.').pop().toLowerCase();
        if (ext === 'm4a') mime = 'audio/m4a';
        else if (ext === 'mp3') mime = 'audio/mp3';
        else if (ext === 'wav') mime = 'audio/wav';
        else if (ext === 'webm') mime = 'audio/webm';
        else mime = 'audio/m4a';
      }
      return mime;
    }

    // Google Files API (Resumable Upload)
    async function uploadToFileAPI(file, apiKey) {
      const mimeType = getCorrectMimeType(file);
      const numBytes = file.size;

      const initUrl = `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${apiKey}`;
      const initResponse = await fetch(initUrl, {
        method: 'POST',
        headers: {
          'X-Goog-Upload-Protocol': 'resumable',
          'X-Goog-Upload-Command': 'start',
          'X-Goog-Upload-Header-Content-Length': numBytes.toString(),
          'X-Goog-Upload-Header-Content-Type': mimeType,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ file: { displayName: file.name } })
      });

      if (!initResponse.ok) {
        const errJson = await initResponse.json().catch(() => ({}));
        throw new Error(`Upload Init Error (${initResponse.status}): ${errJson.error?.message || ''}`);
      }

      const uploadUrl = initResponse.headers.get('X-Goog-Upload-URL');
      if (!uploadUrl) throw new Error('Upload URLを取得できませんでした。');

      const uploadResponse = await fetch(uploadUrl, {
        method: 'POST',
        headers: {
          'Content-Length': numBytes.toString(),
          'X-Goog-Upload-Offset': '0',
          'X-Goog-Upload-Command': 'upload, finalize'
        },
        body: file
      });

      if (!uploadResponse.ok) {
        const errJson = await uploadResponse.json().catch(() => ({}));
        throw new Error(`Upload Binary Error (${uploadResponse.status}): ${errJson.error?.message || ''}`);
      }

      const result = await uploadResponse.json();
      return result.file;
    }

    async function waitForFileActive(fileObj, apiKey) {
      const getUrl = `https://generativelanguage.googleapis.com/v1beta/${fileObj.name}?key=${apiKey}`;
      while (true) {
        const response = await fetch(getUrl);
        if (!response.ok) {
          const errJson = await response.json().catch(() => ({}));
          throw new Error(`ファイル状態取得失敗 (${response.status}): ${errJson.error?.message || ''}`);
        }
        const data = await response.json();
        if (data.state === 'ACTIVE') return data;
        if (data.state === 'FAILED') throw new Error('サーバー処理でエラーが発生しました。');

        loading.textContent = 'Googleサーバー上で音声ファイルを処理中...';
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    async function fetchWithJitterRetry(endpoint, requestBody, maxRetries = 4) {
      let baseDelay = 2000;
      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          loading.textContent = `Gemini 3.8 Flashで要約・解析中... (${attempt}/${maxRetries}回目)`;

          const response = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
          });

          if (response.ok) return await response.json();

          const errData = await response.json().catch(() => ({}));
          const errMsg = errData.error?.message || '';
          const status = response.status;

          if (status === 429 && (errMsg.includes('quota') || errMsg.includes('RESOURCE_EXHAUSTED'))) {
            throw new Error('QUOTA_EXCEEDED');
          }

          if (status === 503 || status === 429 || status === 408 || status >= 500 || errMsg.includes('demand')) {
            if (attempt < maxRetries) {
              const jitter = Math.floor(Math.random() * 1000);
              const waitTime = baseDelay + jitter;
              loading.textContent = `サーバー混雑を検知。${(waitTime / 1000).toFixed(1)}秒後に自動再試行します...`;
              await new Promise(resolve => setTimeout(resolve, waitTime));
              baseDelay *= 2;
              continue;
            }
          }
          throw new Error(errMsg || `HTTP Error ${status}`);
        } catch (error) {
          if (error.message === 'QUOTA_EXCEEDED') {
            throw new Error('本日の無料利用制限（クォータ）に達しました。時間を置くか明日お試しください。');
          }
          if (attempt === maxRetries) throw error;

          const jitter = Math.floor(Math.random() * 1000);
          const waitTime = baseDelay + jitter;
          loading.textContent = `通信エラーが発生しました。${(waitTime / 1000).toFixed(1)}秒後に再接続を試みます...`;
          await new Promise(resolve => setTimeout(resolve, waitTime));
          baseDelay *= 2;
        }
      }
    }

    async function analyzeAudio() {
      const apiKey = apiKeyInput.value.trim();
      if (!apiKey) {
        alert('Gemini APIキーを入力してください。');
        return;
      }
      if (!selectedFile) {
        alert('音声ファイルを選択してください。');
        return;
      }

      analyzeBtn.disabled = true;
      loading.style.display = 'block';
      resultCard.style.display = 'none';

      try {
        // 1. 必要に応じてブラウザ内で自動圧縮
        const targetFile = await compressAudioIfNeeded(selectedFile);

        // 2. Google Files API へアップロード
        loading.textContent = '軽量化された音声データを Google Files API へアップロード中...';
        const uploadedFile = await uploadToFileAPI(targetFile, apiKey);
        await waitForFileActive(uploadedFile, apiKey);

        // 3. プロンプト送信
        const promptText = `
音声ファイルを注意深く聞き取り、全体の「要約」と「文字起こし」を行ってください。

【音質・複数話者への対応】
1. 音質が小さかったり反響・ノイズがある場合も、前後の文脈から最も自然で正しい言葉を推測して自動補完してください。
2. 複数の人物が会話している場合は、発言の頭に「話者A:」「話者B:」のように可能な限り区別して記述してください。

【必須要件】
1. summary: 会議全体の簡潔な要約・決定事項・アジェンダを箇条書きで記載してください。
2. transcripts: 発言の区切り（開始時間 start_time：秒数）ごとに文字起こしを行ってください。
3. 文脈から不自然な言い間違い、誤変換、音声ノイズと思われる箇所は、自然な正しい言葉に「自動補完」してください。
4. 自動補完・修正した箇所は、必ずHTMLタグの <mark>補完後の言葉</mark> で囲んで目立たせてください。また、補完を含んだ発言ブロックには "has_correction": true を付与してください。

【出力形式】
以下のキーを持つJSONオブジェクト形式のみで返答してください。余計な文章や記号は含めないでください。

{
  "summary": "・議題：〜〜\\n・決定事項：〜〜",
  "transcripts": [
    {
      "start_time": 0,
      "text": "話者A: テキスト内容。<mark>補完箇所</mark>テキスト続く。",
      "has_correction": true
    }
  ]
}
`;

        const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${apiKey}`;
        const mimeType = getCorrectMimeType(targetFile);

        const requestBody = {
          contents: [
            {
              parts: [
                { text: promptText },
                { fileData: { mimeType: mimeType, fileUri: uploadedFile.uri } }
              ]
            }
          ],
          generationConfig: {
            responseMimeType: "application/json"
          }
        };

        const data = await fetchWithJitterRetry(endpoint, requestBody, 4);
        const jsonText = data.candidates[0].content.parts[0].text;
        fullResultData = JSON.parse(jsonText);

        summaryArea.textContent = fullResultData.summary || '要約はありません。';
        renderResults('all');
        resultCard.style.display = 'block';

      } catch (error) {
        console.error(error);
        alert(`エラー: ${error.message}`);
      } finally {
        analyzeBtn.disabled = false;
        loading.style.display = 'none';
      }
    }

    function renderResults(mode) {
      transcriptContainer.innerHTML = '';
      if (!fullResultData || !Array.isArray(fullResultData.transcripts)) return;

      const list = fullResultData.transcripts;
      let count = 0;

      list.forEach((item, index) => {
        const hasMark = item.text.includes('<mark>') || item.has_correction;
        if (mode === 'highlight' && !hasMark) return;

        count++;
        const li = document.createElement('li');
        const displayTime = formatTime(item.start_time);

        li.innerHTML = `
          <button class="timestamp-btn" onclick="seekTo(${item.start_time})">${displayTime}</button>
          <div class="editable-text" contenteditable="true" data-index="${index}">${item.text}</div>
        `;
        transcriptContainer.appendChild(li);
      });

      if (count === 0) {
        transcriptContainer.innerHTML = '<li style="color:#888;">該当する結果がありませんでした。</li>';
      }
    }

    function filterList(mode) {
      document.getElementById('btnShowAll').classList.toggle('active', mode === 'all');
      document.getElementById('btnShowHighlights').classList.toggle('active', mode === 'highlight');
      renderResults(mode);
    }

    function copyResults() {
      const summaryText = summaryArea.innerText;
      let text = `【会議要約】\n${summaryText}\n\n【文字起こし】\n`;

      const items = transcriptContainer.querySelectorAll('li');
      items.forEach(li => {
        const btn = li.querySelector('.timestamp-btn');
        const div = li.querySelector('.editable-text');
        if (btn && div) {
          const time = btn.innerText;
          const content = div.innerText;
          text += `[${time}] ${content}\n`;
        }
      });

      navigator.clipboard.writeText(text).then(() => {
        alert('画面上で修正された最新テキストをクリップボードにコピーしました！');
      });
    }

    function downloadResults() {
      const summaryText = summaryArea.innerText;
      let text = `【会議要約】\n${summaryText}\n\n【文字起こし】\n`;

      const items = transcriptContainer.querySelectorAll('li');
      items.forEach(li => {
        const btn = li.querySelector('.timestamp-btn');
        const div = li.querySelector('.editable-text');
        if (btn && div) {
          const time = btn.innerText;
          const content = div.innerText;
          text += `[${time}] ${content}\n`;
        }
      });

      const blob = new Blob([text], { type: 'text/plain' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = `meeting_transcript_${new Date().toISOString().slice(0,10)}.txt`;
      a.click();
    }
  </script>

</body>
</html>
