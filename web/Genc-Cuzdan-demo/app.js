/**
 * Genç Cüzdan - Client-Side Demo Application JavaScript Engine
 * Resets completely on page refresh. Full feature set without login.
 */

// ── INITIAL SEED DATA (In-Memory State) ──
function getInitialState() {
  return {
    user: {
      name: "Demo Kullanıcı",
      jobType: "öğrenci",
      salary: 3500
    },
    investmentProfile: null, // 'korumacı', 'dengeli', 'agresif' or null
    selectedCurrencies: ['USD/TL', 'EUR/TL', 'Gram Altın', 'BTC/TL'],
    marketRates: {
      'USD/TL': 44.36,
      'EUR/TL': 51.45,
      'GBP/TL': 56.20,
      'JPY/TL': 0.296,
      'CHF/TL': 50.10,
      'CNY/TL': 6.10,
      'Gram Altın': 6500.0,
      'Gümüş': 55.0,
      'BTC/TL': 3160000.0,
      'ETH/TL': 72000.0,
      'TRY': 1.0
    },
    goals: [
      {
        id: 1,
        title: 'Kablosuz Kulaklık',
        target_amount: 2500,
        category: 'Teknoloji',
        icon: '🎧',
        is_need: false,
        is_completed: false,
        color: '#6366F1'
      },
      {
        id: 2,
        title: 'İspanyolca Kursu',
        target_amount: 4000,
        category: 'Eğitim',
        icon: '🎓',
        is_need: true,
        is_completed: false,
        color: '#3B82F6'
      },
      {
        id: 3,
        title: 'Dağ Bisikleti',
        target_amount: 8500,
        category: 'Spor',
        icon: '🚲',
        is_need: false,
        is_completed: true,
        completed_at: '2026-06-15 14:30',
        color: '#10B981'
      }
    ],
    savings: [
      { id: 101, amount: 5000, currency: 'TRY', description: 'Vadesiz Hesap', date: '2026-07-01' },
      { id: 102, amount: 250, currency: 'USD', description: 'Dolar Birikimi', date: '2026-07-05' },
      { id: 103, amount: 1.5, currency: 'GOLD', description: 'Gram Altın', date: '2026-07-10' }
    ],
    activities: [
      { id: 1, date: getTodayStr(), type: 'gelir', amount: 3500, description: 'Aylık Harçlık / Maaş', category: 'Gelir', currency: 'TRY', is_need: true },
      { id: 2, date: getTodayStr(), type: 'gider', amount: 120, description: 'Kantin & Kahve', category: 'Gıda', currency: 'TRY', is_need: true },
      { id: 3, date: getPastDateStr(2), type: 'gelir', amount: 1000, description: 'Kulaklık Hedefi Birikimi', category: 'Hedef', goal_id: 1, currency: 'TRY', is_need: false },
      { id: 4, date: getPastDateStr(5), type: 'gider', amount: 250, description: 'Ders Kitapları', category: 'Eğitim', currency: 'TRY', is_need: true },
      { id: 5, date: getPastDateStr(10), type: 'gider', amount: 90, description: 'Müzik Platformu Aboneliği', category: 'Abonelik', currency: 'TRY', is_need: false },
      { id: 6, date: getPastDateStr(30), type: 'gelir', amount: 8500, description: 'Dağ Bisikleti Birikimi', category: 'Hedef', goal_id: 3, currency: 'TRY', is_need: false }
    ],
    savedExpenses: [
      { id: 1, label: 'Kantin Tost & Ayran', amount: 75, category: 'Gıda' },
      { id: 2, label: 'Otobüs / Dolmuş', amount: 30, category: 'Ulaşım' },
      { id: 3, label: 'Filtre Kahve', amount: 95, category: 'Gıda' },
      { id: 4, label: 'Dijital Platform', amount: 120, category: 'Abonelik' }
    ],
    calendarDate: {
      year: new Date().getFullYear(),
      month: new Date().getMonth() + 1
    },
    termsLevel: 'basic', // 'basic' | 'advanced'
    termsSearch: '',
    goalsTab: 'active', // 'active' | 'completed'
    chatMessages: [
      {
        text: "👋 Merhaba **Demo Kullanıcı**! Ben **Finans Asistanın**.\n\nFinansal sorularınızı yanıtlamak, bütçe planlamanıza yardımcı olmak ve para yönetimi konusunda rehberlik etmek için buradayım.\n\nAşağıdaki konulardan birini seçebilir veya kendi sorunuzu yazabilirsiniz! 💬",
        isUser: false,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      }
    ]
  };
}

let state = getInitialState();

// ── UTILITY FUNCTIONS ──
function getTodayStr() {
  const d = new Date();
  return d.toISOString().split('T')[0];
}

function getPastDateStr(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString().split('T')[0];
}

function formatTry(amount) {
  return '₺' + Number(amount || 0).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

function convertToTry(amount, currency) {
  if (currency === 'TRY') return amount;
  const rates = state.marketRates;
  if (currency === 'USD') return amount * (rates['USD/TL'] || 44.36);
  if (currency === 'EUR') return amount * (rates['EUR/TL'] || 51.45);
  if (currency === 'GOLD' || currency === 'GRAM ALTIN') return amount * (rates['Gram Altın'] || 6500.0);
  if (currency === 'BTC') return amount * (rates['BTC/TL'] || 3160000.0);
  return amount;
}

function convertFromTry(tryAmount, targetCurrency) {
  if (targetCurrency === 'TRY') return tryAmount;
  const rates = state.marketRates;
  if (targetCurrency === 'USD') return tryAmount / (rates['USD/TL'] || 44.36);
  if (targetCurrency === 'EUR') return tryAmount / (rates['EUR/TL'] || 51.45);
  if (targetCurrency === 'GOLD' || targetCurrency === 'GRAM ALTIN') return tryAmount / (rates['Gram Altın'] || 6500.0);
  if (targetCurrency === 'BTC') return tryAmount / (rates['BTC/TL'] || 3160000.0);
  return tryAmount;
}

function showToast(message, icon = '✨') {
  const toast = document.getElementById('toast');
  toast.innerHTML = `<span>${icon}</span> <span>${message}</span>`;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3000);
}

function triggerConfetti() {
  if (typeof confetti === 'function') {
    confetti({
      particleCount: 120,
      spread: 80,
      origin: { y: 0.6 }
    });
  }
}

// ── DOM CONTENT LOADED INITIALIZATION ──
document.addEventListener('DOMContentLoaded', () => {
  initLiveRates();
  renderApp();
});

// ── LIVE RATES FETCHING ──
async function initLiveRates() {
  try {
    // Bug #9 fix: abort if the request takes longer than 5 seconds
    const controller = new AbortController();
    const tid = setTimeout(() => controller.abort(), 5000);
    const res = await fetch('https://open.er-api.com/v6/latest/USD', { signal: controller.signal });
    clearTimeout(tid);
    if (res.ok) {
      const data = await res.json();
      if (data && data.rates && data.rates.TRY) {
        const usdTry = data.rates.TRY;
        state.marketRates['USD/TL'] = Math.round(usdTry * 100) / 100;
        if (data.rates.EUR) state.marketRates['EUR/TL'] = Math.round((usdTry / data.rates.EUR) * 100) / 100;
        if (data.rates.GBP) state.marketRates['GBP/TL'] = Math.round((usdTry / data.rates.GBP) * 100) / 100;
        renderHomeMarketRates();
        renderWalletHero();
      }
    }
  } catch (e) {
    console.log("Using static default market rates");
  }
}

// ── MAIN RENDER ENGINE ──
function renderApp() {
  renderHome();
  renderWallet();
  renderChat();
  renderTerms();
  renderProfile();
}

// ── NAVIGATION ──
function switchTab(tabName) {
  document.querySelectorAll('.nav-item').forEach(el => {
    if (el.dataset.tab === tabName) el.classList.add('active');
    else el.classList.remove('active');
  });

  document.querySelectorAll('.page').forEach(el => {
    if (el.id === `page-${tabName}`) el.classList.add('active');
    else el.classList.remove('active');
  });

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ── PAGE 1: HOME RENDERERS ──
function renderHome() {
  document.getElementById('home-welcome-name').textContent = state.user.name || 'Demo Kullanıcı';
  renderHomeGoals();
  renderHomeCalendar();
  renderHomeMarketRates();
  renderHomeRecentTransactions();
}

function getGoalSavedAmount(goalId) {
  let saved = 0;
  state.activities.filter(a => a.goal_id === goalId).forEach(a => {
    const tryAmt = convertToTry(a.amount, a.currency || 'TRY');
    if (a.type === 'gelir') saved += tryAmt;
    else if (a.type === 'gider') saved -= tryAmt;
  });
  return Math.max(0, saved);
}

function renderHomeGoals() {
  const container = document.getElementById('home-goals-container');
  const filtered = state.goals.filter(g => state.goalsTab === 'completed' ? g.is_completed : !g.is_completed);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="grid-column:1/-1; text-align:center; padding:32px; color:var(--gray); background:white; border-radius:24px; border:1px dashed #E2E8F0;">
        ${state.goalsTab === 'completed' ? 'Henüz tamamlanan bir hedef yok.' : 'Henüz bir hedefiniz yok. Hızlı işlemlerden yeni hedef ekleyebilirsiniz!'}
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(goal => {
    const saved = getGoalSavedAmount(goal.id);
    const pct = goal.is_completed ? 100 : Math.min(100, Math.round((saved / goal.target_amount) * 100));
    const displaySaved = goal.is_completed ? Math.max(saved, goal.target_amount) : saved;

    return `
      <div class="goal-card">
        <div onclick="openGoalDetailModal(${goal.id})" style="cursor:pointer;">
          <div class="goal-card-header">
            <div class="goal-icon">${goal.icon || '🎯'}</div>
            <div class="goal-pct">%${pct}</div>
          </div>
          <div class="goal-name">${goal.title}</div>
          <div class="goal-category-badge">${goal.is_need ? '📌 İhtiyaç' : '✨ İstek'} • ${goal.category}</div>
          <div class="goal-amount-row">
            <div class="goal-amount">${formatTry(displaySaved)}</div>
            <div class="goal-target">Hedef: ${formatTry(goal.target_amount)}</div>
          </div>
          <div class="goal-progress-bar">
            <div class="fill" style="width: ${pct}%"></div>
          </div>
        </div>
        <div class="goal-card-footer">
          ${!goal.is_completed ? `
            <button class="btn-sm btn-secondary" onclick="openFundGoalModal(${goal.id})">💰 Para Aktar</button>
            ${pct >= 100 ? `<button class="btn-sm btn-primary" onclick="purchaseGoal(${goal.id})">🎉 Satın Al</button>` : ''}
          ` : `
            <span style="font-size:12px; font-weight:700; color:var(--green)">✅ Tamamlandı</span>
          `}
        </div>
      </div>
    `;
  }).join('');
}

function setGoalsTab(tab) {
  state.goalsTab = tab;
  document.getElementById('tab-btn-active').classList.toggle('active', tab === 'active');
  document.getElementById('tab-btn-completed').classList.toggle('active', tab === 'completed');
  renderHomeGoals();
}

function renderHomeCalendar() {
  const { year, month } = state.calendarDate;
  const monthNames = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
  document.getElementById('calendar-month-title').textContent = `${monthNames[month - 1]} ${year}`;

  const daysInMonth = new Date(year, month, 0).getDate();
  const firstDayIndex = (new Date(year, month - 1, 1).getDay() + 6) % 7; // Monday start

  // Dates with activities
  const activeDays = new Set();
  state.activities.forEach(a => {
    if (a.date) {
      const parts = a.date.split('-');
      if (parseInt(parts[0]) === year && parseInt(parts[1]) === month) {
        activeDays.add(parseInt(parts[2]));
      }
    }
  });

  const today = new Date();
  const isCurrentMonth = today.getFullYear() === year && (today.getMonth() + 1) === month;

  let html = '';
  for (let i = 0; i < firstDayIndex; i++) {
    html += `<div class="calendar-day empty"></div>`;
  }
  for (let day = 1; day <= daysInMonth; day++) {
    const isToday = isCurrentMonth && today.getDate() === day;
    const hasAct = activeDays.has(day);
    html += `
      <div class="calendar-day ${isToday ? 'today' : ''} ${hasAct ? 'has-activity' : ''}" onclick="showDayActivities('${year}-${String(month).padStart(2,'0')}-${String(day).padStart(2,'0')}')">
        ${day}
      </div>
    `;
  }

  document.getElementById('calendar-days-grid').innerHTML = html;
}

function changeCalendarMonth(delta) {
  let { year, month } = state.calendarDate;
  month += delta;
  if (month > 12) { month = 1; year++; }
  if (month < 1) { month = 12; year--; }
  state.calendarDate = { year, month };
  renderHomeCalendar();
}

function renderHomeMarketRates() {
  const registry = {
    'USD/TL': { name: 'ABD Doları', symbol: '$', color: '#10B981' },
    'EUR/TL': { name: 'Euro', symbol: '€', color: '#6366F1' },
    'GBP/TL': { name: 'İngiliz Sterlini', symbol: '£', color: '#8B5CF6' },
    'Gram Altın': { name: 'Gram Altın', symbol: '₺', color: '#F59E0B' },
    'BTC/TL': { name: 'Bitcoin', symbol: '₿', color: '#F97316' },
    'ETH/TL': { name: 'Ethereum', symbol: 'Ξ', color: '#6366F1' },
    'JPY/TL': { name: 'Japon Yeni', symbol: '¥', color: '#EF4444' },
    'CHF/TL': { name: 'İsviçre Frangı', symbol: 'Fr', color: '#DC2626' },
    'Gümüş': { name: 'Gümüş (gram)', symbol: '₺', color: '#94A3B8' },
    'CNY/TL': { name: 'Çin Yuanı', symbol: '¥', color: '#DC2626' }
  };

  const container = document.getElementById('currency-grid-container');
  container.innerHTML = state.selectedCurrencies.map(key => {
    const info = registry[key] || { name: key, symbol: '₺', color: '#6366F1' };
    const rate = state.marketRates[key] || 0;
    return `
      <div class="currency-card">
        <div class="currency-top">
          <div class="currency-symbol-icon" style="background:${info.color}">${info.symbol}</div>
          <div class="currency-name">${info.name}</div>
        </div>
        <div class="currency-rate">₺${rate.toLocaleString('tr-TR')}</div>
      </div>
    `;
  }).join('');
}

function renderHomeRecentTransactions() {
  const container = document.getElementById('recent-transactions-container');
  if (state.activities.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:20px; color:var(--gray);">Henüz işlem kaydı yok</div>`;
    return;
  }

  const sorted = [...state.activities].sort((a,b) => new Date(b.date) - new Date(a.date)).slice(0, 6);
  container.innerHTML = sorted.map(tx => `
    <div class="transaction-item">
      <div class="tx-icon" style="background: ${tx.type === 'gelir' ? '#D1FAE5' : '#FEE2E2'}; color: ${tx.type === 'gelir' ? '#10B981' : '#EF4444'};">
        ${tx.type === 'gelir' ? '↑' : '↓'}
      </div>
      <div class="tx-info">
        <div class="tx-desc">${tx.description}</div>
        <div class="tx-cat">${tx.category} • ${tx.date}</div>
      </div>
      <div class="tx-amount">
        <div class="tx-value ${tx.type === 'gelir' ? 'income' : 'expense'}">${tx.type === 'gelir' ? '+' : '-'}${formatTry(tx.amount)}</div>
      </div>
    </div>
  `).join('');
}

// ── PAGE 2: WALLET RENDERERS ──
function renderWallet() {
  renderWalletHero();
  renderWalletSavings();
  renderWalletGoalsSummary();
  renderWalletNeedsWants();
  renderWalletInvestment();
}

function renderWalletHero() {
  let totalTry = 0;
  const breakdownMap = {};

  state.savings.forEach(s => {
    const tryVal = convertToTry(s.amount, s.currency);
    totalTry += tryVal;
    breakdownMap[s.currency] = (breakdownMap[s.currency] || 0) + tryVal;
  });

  document.getElementById('wallet-grand-total').textContent = formatTry(totalTry);

  const barContainer = document.getElementById('asset-bar-container');
  const legendContainer = document.getElementById('asset-legend-container');

  const colors = { 'TRY': '#EF4444', 'USD': '#10B981', 'EUR': '#6366F1', 'GOLD': '#F59E0B', 'BTC': '#F97316' };

  let barHtml = '';
  let legendHtml = '';

  Object.keys(breakdownMap).forEach(curr => {
    const tryVal = breakdownMap[curr];
    const pct = totalTry > 0 ? (tryVal / totalTry * 100) : 0;
    const color = colors[curr] || '#64748B';

    barHtml += `<div style="width:${pct}%; background:${color};"></div>`;
    legendHtml += `
      <span>
        <div class="legend-dot" style="background:${color}"></div>
        ${curr} %${Math.round(pct)}
      </span>
    `;
  });

  barContainer.innerHTML = barHtml || '<div style="width:100%; background:rgba(255,255,255,0.2)"></div>';
  legendContainer.innerHTML = legendHtml;

  let monthlyInc = 0;
  let monthlyExp = 0;
  state.activities.forEach(a => {
    const tryAmt = convertToTry(a.amount, a.currency || 'TRY');
    if (a.type === 'gelir') monthlyInc += tryAmt;
    else if (a.type === 'gider') monthlyExp += tryAmt;
  });

  document.getElementById('wallet-inc-total').textContent = formatTry(monthlyInc);
  document.getElementById('wallet-exp-total').textContent = formatTry(monthlyExp);
  document.getElementById('wallet-net-total').textContent = formatTry(monthlyInc - monthlyExp);
}

function renderWalletSavings() {
  const container = document.getElementById('savings-list-container');
  if (state.savings.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:20px; color:var(--gray);">Henüz varlık kaydınız yok</div>`;
    return;
  }

  const colors = { 'TRY': '#EF4444', 'USD': '#10B981', 'EUR': '#6366F1', 'GOLD': '#F59E0B' };
  container.innerHTML = state.savings.map(s => {
    const color = colors[s.currency] || '#6366F1';
    const tryVal = convertToTry(s.amount, s.currency);

    return `
      <div class="savings-item">
        <div class="savings-left">
          <div class="savings-badge" style="background:${color}">${s.currency}</div>
          <div>
            <div style="font-weight:700; font-size:15px;">${s.description || s.currency}</div>
            <div style="font-size:12px; color:var(--gray);">${s.amount} ${s.currency}</div>
          </div>
        </div>
        <div style="text-align:right;">
          <div style="font-weight:800; font-size:16px;">${formatTry(tryVal)}</div>
          <div style="display:flex; gap:6px; justify-content:flex-end; margin-top:4px;">
            <button class="btn-sm btn-secondary" onclick="openTransferSavingModal(${s.id})">🔄 Çevir</button>
            <button class="btn-sm btn-danger" style="padding:4px 8px;" onclick="deleteSaving(${s.id})">🗑️</button>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

function renderWalletNeedsWants() {
  let needsTotal = 0;
  let wantsTotal = 0;

  state.goals.forEach(g => {
    if (g.is_need) needsTotal += g.target_amount;
    else wantsTotal += g.target_amount;
  });

  const total = needsTotal + wantsTotal;
  const needsPct = total > 0 ? (needsTotal / total * 100) : 50;
  const wantsPct = total > 0 ? (wantsTotal / total * 100) : 50;

  document.getElementById('nw-bar-container').innerHTML = `
    <div style="width:${needsPct}%; background:var(--primary);"></div>
    <div style="width:${wantsPct}%; background:var(--coral);"></div>
  `;
  document.getElementById('nw-needs-text').textContent = `İhtiyaç (${formatTry(needsTotal)})`;
  document.getElementById('nw-wants-text').textContent = `İstek (${formatTry(wantsTotal)})`;
}

function renderWalletGoalsSummary() {
  const activeCount = state.goals.filter(g => !g.is_completed).length;
  const completedCount = state.goals.filter(g => g.is_completed).length;
  document.getElementById('goals-summary-active-count').textContent = activeCount;
  document.getElementById('goals-summary-completed-count').textContent = completedCount;
}

function renderWalletInvestment() {
  const container = document.getElementById('investment-section-container');
  if (!state.investmentProfile) {
    container.innerHTML = `
      <div style="text-align:center; padding:28px; background:white; border-radius:24px; box-shadow:var(--shadow);">
        <div style="font-size:36px; margin-bottom:12px;">📊</div>
        <div class="subheading" style="margin-bottom:8px;">Yatırım Profilinizi Belirleyin</div>
        <p style="font-size:14px; color:var(--gray); margin-bottom:20px;">Risk toleransınızı ölçmek ve size özel portföy önerisi almak için testi tamamlayın.</p>
        <button class="btn btn-primary" onclick="openInvestmentTestModal()">Testi Başlat</button>
      </div>
    `;
    return;
  }

  const profiles = {
    'korumacı': {
      title: 'Korumacı Strateji',
      desc: 'Düşük risk, ana parayı koruma ve sabit getiri odaklı yaklaşım.',
      color: '#6366F1',
      alloc: [ { name: 'Mevduat / Repo', pct: 50, color: '#6366F1' }, { name: 'Altın', pct: 30, color: '#F59E0B' }, { name: 'Döviz', pct: 20, color: '#10B981' } ]
    },
    'dengeli': {
      title: 'Dengeli Strateji',
      desc: 'Orta risk, sabit getiri ve büyüme potansiyeli arasında dengeli dağılım.',
      color: '#F59E0B',
      alloc: [ { name: 'Hisse Senedi', pct: 40, color: '#F97316' }, { name: 'Altın / Emtia', pct: 30, color: '#F59E0B' }, { name: 'Mevduat', pct: 30, color: '#6366F1' } ]
    },
    'agresif': {
      title: 'Agresif Büyüme Stratejisi',
      desc: 'Yüksek risk toleransı ile maksimum uzun vadeli sermaye kazancı hedefi.',
      color: '#EF4444',
      alloc: [ { name: 'Hisse Senedi', pct: 60, color: '#EF4444' }, { name: 'Kripto Para', pct: 25, color: '#F97316' }, { name: 'Altın', pct: 15, color: '#F59E0B' } ]
    }
  };

  const prof = profiles[state.investmentProfile] || profiles['dengeli'];

  container.innerHTML = `
    <div class="strategy-card" style="border-top: 4px solid ${prof.color}">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
        <span class="subheading" style="color:${prof.color}">${prof.title}</span>
        <button class="btn-sm btn-secondary" onclick="openInvestmentTestModal()">Testi Tekrarla</button>
      </div>
      <p style="font-size:14px; color:var(--gray); margin-bottom:16px;">${prof.desc}</p>
      <div style="font-size:13px; font-weight:700; color:var(--black); margin-bottom:8px;">Önerilen Portföy Dağılımı:</div>
      <div class="portfolio-alloc-bar">
        ${prof.alloc.map(a => `<div style="width:${a.pct}%; background:${a.color};"></div>`).join('')}
      </div>
      <div style="display:flex; flex-wrap:wrap; gap:16px; font-size:12px; font-weight:600;">
        ${prof.alloc.map(a => `
          <span style="display:flex; align-items:center; gap:6px;">
            <div class="legend-dot" style="background:${a.color}"></div> ${a.name} %${a.pct}
          </span>
        `).join('')}
      </div>
    </div>
  `;
}

// ── PAGE 3: AI CHAT RENDERERS ──
function renderChat() {
  const container = document.getElementById('chat-messages-container');
  container.innerHTML = state.chatMessages.map(msg => `
    <div class="chat-bubble-row ${msg.isUser ? 'user' : 'ai'}">
      <div class="chat-bubble ${msg.isUser ? 'user' : 'ai'}">
        ${formatMarkdown(msg.text)}
      </div>
    </div>
  `).join('');

  container.scrollTop = container.scrollHeight;
}

function sendChatMessage(inputVal) {
  const inputEl = document.getElementById('chat-input-field');
  const text = (inputVal || inputEl.value).trim();
  if (!text) return;

  state.chatMessages.push({
    text: text,
    isUser: true,
    timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  });

  inputEl.value = '';
  renderChat();

  const container = document.getElementById('chat-messages-container');
  const typingEl = document.createElement('div');
  typingEl.className = 'chat-bubble-row ai';
  typingEl.innerHTML = `<div class="chat-bubble ai" style="display:flex; gap:4px; align-items:center; padding:12px 18px;"><span>●</span><span>●</span><span>●</span></div>`;
  container.appendChild(typingEl);
  container.scrollTop = container.scrollHeight;

  setTimeout(() => {
    const aiResponse = generateAiResponse(text);
    state.chatMessages.push({
      text: aiResponse,
      isUser: false,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    });
    renderChat();
  }, 800);
}

function generateAiResponse(query) {
  const lower = query.toLowerCase();
  if (lower.includes('tasarruf') || lower.includes('birikim')) {
    return "💰 **Tasarruf için altın kurallar:**\n\n• Gelirinizin en az **%10–20**'sini her ay düzenli biriktirin.\n• Önce kendinize ödeyin: Maaşınız yatar yatmaz tasarrufu ayırın.\n• **50/30/20** kuralını uygulayın.\n\nGençCüzdan'da **Hedefler** sekmesinden tasarruf hedefi koyabilirsiniz! 🎯";
  }
  if (lower.includes('enflasyon') || lower.includes('değer')) {
    return "📈 **Enflasyona karşı korunma yolları:**\n\n• Altın ve döviz gibi değer saklama araçları.\n• Uzun vadede hisse senetleri ve yatırım fonları.\n• Türk Lirası birikimlerini değerlendirme araçları.\n\nDöviz kurlarını Anasayfa'dan canlı takip edebilirsiniz! 💹";
  }
  if (lower.includes('kredi') || lower.includes('kart') || lower.includes('borç')) {
    return "💳 **Kredi Kartı Yönetimi:**\n\n• Asgari tutarı değil, **toplam borcun tamamını** ödeyin.\n• Limitinizin en fazla **%30-40**'ını kullanın.\n• Gereksiz taksitlerden kaçının.";
  }
  if (lower.includes('yatırım') || lower.includes('hisse') || lower.includes('fon')) {
    return "🏦 **Temel Yatırım Araçları:**\n\n• **Vadeli Mevduat**: Düşük risk.\n• **Altın / Değerli Madenler**: Enflasyon kalkanı.\n• **Hisse Senedi**: Uzun vadeli yüksek büyüme potansiyeli.\n\nCüzdan sekmesinden **Yatırım Testi**'ni çözerek profilinizi öğrenin! 📊";
  }
  return `🤔 **"${query}"** sorunuz için finans önerilerimiz:\n\n• Her ay düzenli bütçe takibi yapın.\n• İhtiyaç ve istek harcamalarınızı ayırın.\n• Acil durum fonu oluşturun (3-6 aylık gider kadar).`;
}

function formatMarkdown(str) {
  return str
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\n/g, '<br>');
}

function clearChatHistory() {
  state.chatMessages = [
    {
      text: "👋 Merhaba! Ben Finans Asistanın. Sohbet temizlendi, ne öğrenmek istersiniz?",
      isUser: false,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
  ];
  renderChat();
  showToast("Sohbet temizlendi", "🧹");
}

// ── PAGE 4: TERMS RENDERERS ──
const TERMS_DATA = {
  'Bütçe': {
    basic: 'Paranı nasıl harcayacağını ve biriktireceğini önceden planlamaktır.',
    advanced: 'Belirli bir dönem için öngörülen gelir ve giderlerin dengeli bir şekilde dağıtılmasını sağlayan finansal planlama aracıdır.'
  },
  'Gelir (Kazanç)': {
    basic: 'Cebine giren para. Harçlığın veya çalıştığın işten kazandığın paradır.',
    advanced: 'Bireyin belirli bir süre içinde elde ettiği toplam parasal değerdir.'
  },
  'Gider (Harcama)': {
    basic: 'Cebinden çıkan para. Yiyecek veya alışveriş ödemelerindir.',
    advanced: 'Kişisel ihtiyaçların karşılanması amacıyla yapılan ödemelerin genel adıdır.'
  },
  'Birikim': {
    basic: 'Gelecekte kullanmak üzere kumbarana attığın paradır.',
    advanced: 'Elde edilen gelirin harcanmayan ve gelecekteki hedefler için ayrılan kısmıdır.'
  },
  'İstek': {
    basic: 'Yaşamak için şart olmayan ama sahip olmayı arzuladığın şeyler (oyun konsolu vb.).',
    advanced: 'Temel yaşam gereksinimlerinin ötesinde, yaşam kalitesini artırmaya yönelik elzem olmayan arzular.'
  },
  'İhtiyaç': {
    basic: 'Hayatta kalmak veya günlük yaşamını sürdürmek için kesin gereken şeyler (yemek, su, okul malzemesi).',
    advanced: 'Bireyin yaşamını sağlıklı sürdürebilmesi için karşılanması zorunlu olan temel gereksinimlerdir.'
  },
  'Enflasyon': {
    basic: 'Zamanla ürünlerin fiyatlarının artması ve paranın satın alma gücünün düşmesi.',
    advanced: 'Ekonomide genel fiyat seviyesinin sürekli artması sonucu satın alma gücünün azalması.'
  }
};

function renderTerms() {
  const search = state.termsSearch.toLowerCase();
  const container = document.getElementById('terms-list-container');

  const filtered = Object.keys(TERMS_DATA).filter(key => {
    return key.toLowerCase().includes(search) || TERMS_DATA[key][state.termsLevel].toLowerCase().includes(search);
  });

  container.innerHTML = filtered.map(key => {
    const def = TERMS_DATA[key][state.termsLevel];
    return `
      <div class="term-card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
          <div class="term-title">${key}</div>
          <span style="font-size:11px; padding:4px 10px; border-radius:12px; font-weight:700; background:rgba(99,102,241,0.1); color:var(--primary)">
            ${state.termsLevel === 'basic' ? 'Temel' : 'İleri'}
          </span>
        </div>
        <div class="term-desc">${def}</div>
      </div>
    `;
  }).join('');
}

function setTermsLevel(level) {
  state.termsLevel = level;
  document.getElementById('terms-btn-basic').classList.toggle('active', level === 'basic');
  document.getElementById('terms-btn-advanced').classList.toggle('active', level === 'advanced');
  renderTerms();
}

function filterTerms(val) {
  state.termsSearch = val;
  renderTerms();
}

// ── PAGE 5: PROFILE RENDERERS ──
function renderProfile() {
  document.getElementById('profile-input-name').value = state.user.name || '';
  document.getElementById('profile-input-salary').value = state.user.salary || '';
  
  ['profile-avatar-img', 'home-user-avatar-img'].forEach(id => {
    const img = document.getElementById(id);
    if (img) img.src = 'assets/profile.svg';
  });

  renderProfileBadges();
}

function renderProfileBadges() {
  const completedGoalsCount = state.goals.filter(g => g.is_completed).length;

  const badges = [
    { title: 'İlk Adım', threshold: 1, icon: '⭐' },
    { title: 'İkili Zafer', threshold: 2, icon: '🚲' },
    { title: 'Hedef Avcısı', threshold: 3, icon: '🎯' },
    { title: 'Tasarruf Ustası', threshold: 4, icon: '🐷' },
    { title: 'Kararlı Birikimci', threshold: 5, icon: '📈' },
    { title: 'Finans Gurusu', threshold: 6, icon: '🧠' },
    { title: 'Hedef Canavarı', threshold: 7, icon: '🦁' },
    { title: 'Yıldız Tasarrufçu', threshold: 8, icon: '🌟' },
    { title: 'Efsanevi Bütçeci', threshold: 10, icon: '👑' }
  ];

  const container = document.getElementById('badges-grid-container');
  container.innerHTML = badges.map(b => {
    const isUnlocked = completedGoalsCount >= b.threshold;
    return `
      <div class="badge-item">
        <div class="badge-circle ${isUnlocked ? 'unlocked' : 'locked'}">
          ${isUnlocked ? b.icon : '🔒'}
        </div>
        <div class="badge-name">${b.title}</div>
        <div class="badge-req">${b.threshold} Hedef</div>
      </div>
    `;
  }).join('');
}

function saveProfileChanges() {
  const name = document.getElementById('profile-input-name').value.trim();
  const salary = parseFloat(document.getElementById('profile-input-salary').value) || 0;

  if (name) state.user.name = name;
  state.user.salary = salary;

  renderApp();
  showToast("Profil kaydedildi", "✅");
}

// ── MODAL ACTIONS & EVENT LISTENERS ──
function openModal(id) {
  document.getElementById(id).classList.add('show');
}

function closeModal(id) {
  document.getElementById(id).classList.remove('show');
}

// Goal Detail Modal
function openGoalDetailModal(goalId) {
  const goal = state.goals.find(g => g.id === goalId);
  if (!goal) return;

  const saved = getGoalSavedAmount(goal.id);
  const pct = goal.is_completed ? 100 : Math.min(100, Math.round((saved / goal.target_amount) * 100));
  const displaySaved = goal.is_completed ? Math.max(saved, goal.target_amount) : saved;

  const history = state.activities.filter(a => a.goal_id === goal.id);

  document.getElementById('goal-detail-title').textContent = `${goal.icon || '🎯'} ${goal.title}`;
  document.getElementById('goal-detail-status-badge').textContent = goal.is_completed ? '✅ Tamamlandı' : `%${pct} İlerleme`;
  document.getElementById('goal-detail-status-badge').style.background = goal.is_completed ? '#D1FAE5' : 'rgba(99,102,241,0.1)';
  document.getElementById('goal-detail-status-badge').style.color = goal.is_completed ? '#10B981' : 'var(--primary)';

  document.getElementById('goal-detail-body').innerHTML = `
    <div style="margin-bottom:20px; background:var(--light-gray); padding:16px; border-radius:18px;">
      <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-weight:700;">
        <span>Biriken: ${formatTry(displaySaved)}</span>
        <span>Hedef: ${formatTry(goal.target_amount)}</span>
      </div>
      <div class="goal-progress-bar" style="margin-top:0;">
        <div class="fill" style="width: ${pct}%"></div>
      </div>
      <div style="margin-top:12px; font-size:12px; color:var(--gray); font-weight:600;">
        Kategori: ${goal.category} • Tür: ${goal.is_need ? 'İhtiyaç' : 'İstek'}
      </div>
    </div>

    <div style="font-weight:700; font-size:14px; margin-bottom:12px;">Hedef Para Aktarım Geçmişi</div>
    <div style="display:flex; flex-direction:column; gap:8px; max-height:200px; overflow-y:auto;">
      ${history.length === 0 ? '<div style="font-size:13px; color:var(--gray);">Henüz bu hedefe yapılan bir aktarım yok.</div>' : history.map(h => `
        <div style="display:flex; justify-content:space-between; align-items:center; padding:10px 14px; background:white; border-radius:14px; border:1px solid #E2E8F0;">
          <div>
            <div style="font-size:13px; font-weight:700;">${h.description}</div>
            <div style="font-size:11px; color:var(--gray);">${h.date}</div>
          </div>
          <div style="font-weight:800; color:var(--green); font-size:14px;">+${formatTry(h.amount)}</div>
        </div>
      `).join('')}
    </div>
  `;

  openModal('modal-goal-detail');
}

// Add Transaction Modal
function openAddTransactionModal() {
  const select = document.getElementById('tx-goal-select');
  select.innerHTML = '<option value="">(İsteğe Bağlı) Hedefe Bağla</option>' +
    state.goals.filter(g => !g.is_completed).map(g => `<option value="${g.id}">${g.title}</option>`).join('');

  document.getElementById('tx-date').value = getTodayStr();
  openModal('modal-add-transaction');
}

function submitAddTransaction(e) {
  e.preventDefault();
  const desc = document.getElementById('tx-desc').value.trim();
  const amount = parseFloat(document.getElementById('tx-amount').value);
  const type = document.getElementById('tx-type').value;
  const category = document.getElementById('tx-category').value;
  const currency = document.getElementById('tx-currency').value;
  const isNeed = document.getElementById('tx-is-need').value === 'true';
  const goalId = parseInt(document.getElementById('tx-goal-select').value) || null;
  const date = document.getElementById('tx-date').value || getTodayStr();

  if (!desc || isNaN(amount) || amount <= 0) {
    alert("Lütfen geçerli açıklama ve tutar girin.");
    return;
  }

  state.activities.unshift({
    id: Date.now(),
    date, type, amount, description: desc, category, currency, is_need: isNeed, goal_id: goalId
  });

  closeModal('modal-add-transaction');
  renderApp();
  showToast(`${type === 'gelir' ? 'Gelir' : 'Gider'} eklendi`, "💳");
}

// Quick Expense Modal
function openQuickExpenseModal() {
  const container = document.getElementById('quick-expense-chips-container');
  container.innerHTML = state.savedExpenses.map(exp => `
    <button class="quick-chip" onclick="applyQuickExpense(${exp.id})">
      <span>${exp.label}</span>
      <span class="chip-amount">-${formatTry(exp.amount)}</span>
    </button>
  `).join('');
  openModal('modal-quick-expense');
}

function applyQuickExpense(expId) {
  const exp = state.savedExpenses.find(e => e.id === expId);
  if (!exp) return;

  state.activities.unshift({
    id: Date.now(),
    date: getTodayStr(),
    type: 'gider',
    amount: exp.amount,
    description: exp.label,
    category: exp.category,
    currency: 'TRY',
    is_need: true
  });

  closeModal('modal-quick-expense');
  renderApp();
  showToast(`"${exp.label}" gider olarak eklendi`, "⚡");
}

// Add Goal Modal
let selectedGoalIcon = '🎯';
function selectGoalIcon(el, icon) {
  document.querySelectorAll('.icon-option').forEach(i => i.classList.remove('selected'));
  el.classList.add('selected');
  selectedGoalIcon = icon;
}

function openAddGoalModal() {
  // Bug #8 fix: reset the icon picker state every time the modal opens
  selectedGoalIcon = '🎯';
  document.querySelectorAll('.icon-option').forEach(el => el.classList.remove('selected'));
  const firstOption = document.querySelector('.icon-option');
  if (firstOption) firstOption.classList.add('selected');
  openModal('modal-add-goal');
}

function submitAddGoal(e) {
  e.preventDefault();
  const title = document.getElementById('goal-title').value.trim();
  const target = parseFloat(document.getElementById('goal-target').value);
  const category = document.getElementById('goal-category').value;
  const isNeed = document.getElementById('goal-is-need').value === 'true';

  if (!title || isNaN(target) || target <= 0) {
    alert("Geçerli hedef başlığı ve tutarı girin.");
    return;
  }

  state.goals.push({
    id: Date.now(),
    title,
    target_amount: target,
    category,
    icon: selectedGoalIcon,
    is_need: isNeed,
    is_completed: false
  });

  closeModal('modal-add-goal');
  renderApp();
  showToast("Yeni hedef oluşturuldu", "🎯");
}

function deleteGoal(id) {
  if (confirm("Bu hedef silinsin mi?")) {
    state.goals = state.goals.filter(g => g.id !== id);
    renderApp();
    showToast("Hedef silindi", "🗑️");
  }
}

function purchaseGoal(id) {
  const goal = state.goals.find(g => g.id === id);
  if (!goal) return;

  // Bug #4 fix: require a savings asset to deduct from
  if (state.savings.length === 0) {
    showToast("Önce Cüzdan sekmesinden varlık ekleyin.", "⚠️");
    return;
  }

  const savingsTotalTry = state.savings.reduce((sum, s) => sum + convertToTry(s.amount, s.currency), 0);
  if (savingsTotalTry < goal.target_amount - 0.01) {
    showToast("Yeterli varlık bakiyeniz yok!", "⚠️");
    return;
  }

  // Deduct purchase amount from savings in order (largest first)
  let remaining = goal.target_amount;
  const sorted = [...state.savings].sort((a, b) => convertToTry(b.amount, b.currency) - convertToTry(a.amount, a.currency));
  for (const s of sorted) {
    if (remaining <= 0) break;
    const tryVal = convertToTry(s.amount, s.currency);
    if (tryVal <= remaining + 0.01) {
      remaining -= tryVal;
      state.savings = state.savings.filter(x => x.id !== s.id);
    } else {
      const leftTry = tryVal - remaining;
      s.amount = Math.round(convertFromTry(leftTry, s.currency) * 10000) / 10000;
      remaining = 0;
    }
  }

  goal.is_completed = true;
  goal.completed_at = getTodayStr();

  // Add purchase expense record
  state.activities.unshift({
    id: Date.now(),
    date: getTodayStr(),
    type: 'gider',
    amount: goal.target_amount,
    description: `Satın Alma: ${goal.title}`,
    category: 'Hedef',
    currency: 'TRY',
    is_need: goal.is_need
  });

  triggerConfetti();
  renderApp();
  showToast(`Tebrikler! "${goal.title}" hedefinizi aldınız! 🎉`, "🏆");
}

// Fund Goal Modal (Enhanced Precision & Partial Transfer)
let fundTargetGoalId = null;

function openFundGoalModal(goalId) {
  if (state.savings.length === 0) {
    alert("Aktarılacak varlığınız bulunmamaktadır. Lütfen önce Cüzdan sekmesinden varlık ekleyin.");
    return;
  }

  fundTargetGoalId = goalId;
  const goal = state.goals.find(g => g.id === goalId);
  if (!goal) return;

  const currentSaved = getGoalSavedAmount(goal.id);
  const remainingNeeded = Math.max(0, goal.target_amount - currentSaved);

  document.getElementById('fund-goal-title-display').value = goal.title;
  document.getElementById('fund-remaining-hint').textContent = `Hedefin tamamlanması için kalan: ${formatTry(remainingNeeded)}`;

  const select = document.getElementById('fund-saving-select');
  select.innerHTML = state.savings.map(s => {
    const tryVal = convertToTry(s.amount, s.currency);
    return `<option value="${s.id}">${s.description || s.currency} (${s.amount} ${s.currency} ≈ ${formatTry(tryVal)})</option>`;
  }).join('');

  updateFundAmountDefault();
  openModal('modal-fund-goal');
}

function updateFundAmountDefault() {
  const savingId = parseInt(document.getElementById('fund-saving-select').value);
  const saving = state.savings.find(s => s.id === savingId);
  const goal = state.goals.find(g => g.id === fundTargetGoalId);
  if (!saving || !goal) return;

  const currentSaved = getGoalSavedAmount(goal.id);
  const remainingNeeded = Math.max(0, goal.target_amount - currentSaved);
  const savingTryVal = convertToTry(saving.amount, saving.currency);

  const defaultTransferTry = Math.min(savingTryVal, remainingNeeded > 0 ? remainingNeeded : savingTryVal);
  document.getElementById('fund-amount-input').value = Math.round(defaultTransferTry * 100) / 100;
}

function submitFundGoal(e) {
  e.preventDefault();
  const savingId = parseInt(document.getElementById('fund-saving-select').value);
  const fundTryAmt = parseFloat(document.getElementById('fund-amount-input').value);

  const saving = state.savings.find(s => s.id === savingId);
  const goal = state.goals.find(g => g.id === fundTargetGoalId);

  if (!saving || !goal || isNaN(fundTryAmt) || fundTryAmt <= 0) {
    alert("Geçerli bir aktarım tutarı girin.");
    return;
  }

  const savingTotalTry = convertToTry(saving.amount, saving.currency);
  if (fundTryAmt > savingTotalTry + 0.01) {
    alert(`Seçilen varlıkta yeterli bakiye yok! Mevcut Bakiye: ${formatTry(savingTotalTry)}`);
    return;
  }

  // Deduct from saving asset
  if (Math.abs(fundTryAmt - savingTotalTry) < 0.01) {
    // Delete full saving
    state.savings = state.savings.filter(s => s.id !== savingId);
  } else {
    // Partial deduction
    const remainingTry = savingTotalTry - fundTryAmt;
    saving.amount = Math.round(convertFromTry(remainingTry, saving.currency) * 10000) / 10000;
  }

  // Add income activity to goal
  state.activities.unshift({
    id: Date.now(),
    date: getTodayStr(),
    type: 'gelir',
    amount: Math.round(fundTryAmt * 100) / 100,
    description: `Varlıktan Hedefe: ${saving.currency} → ${goal.title}`,
    category: 'Hedef',
    goal_id: goal.id,
    currency: 'TRY'
  });

  closeModal('modal-fund-goal');
  renderApp();

  const newSaved = getGoalSavedAmount(goal.id);
  if (newSaved >= goal.target_amount && !goal.is_completed) {
    triggerConfetti();
    showToast(`Tebrikler! "${goal.title}" hedefine ulaşıldı!`, "🎉");
  } else {
    showToast(`${formatTry(fundTryAmt)} "${goal.title}" hedefine aktarıldı`, "💰");
  }
}

// Add Saving Asset Modal
function openAddSavingModal() {
  openModal('modal-add-saving');
}

function submitAddSaving(e) {
  e.preventDefault();
  const desc = document.getElementById('saving-desc').value.trim();
  const amount = parseFloat(document.getElementById('saving-amount').value);
  const currency = document.getElementById('saving-currency').value;

  if (isNaN(amount) || amount <= 0) {
    alert("Lütfen geçerli pozitif bir miktar girin.");
    return;
  }

  state.savings.push({
    id: Date.now(),
    amount: Math.round(amount * 10000) / 10000,
    currency,
    description: desc || `${currency} Birikimi`,
    date: getTodayStr()
  });

  closeModal('modal-add-saving');
  renderApp();
  showToast("Varlık eklendi", "💵");
}

function deleteSaving(id) {
  if (confirm("Bu varlık silinsin mi?")) {
    state.savings = state.savings.filter(s => s.id !== id);
    renderApp();
    showToast("Varlık silindi", "🗑️");
  }
}

// Transfer Saving Modal
let transferSourceSavingId = null;
function openTransferSavingModal(savingId) {
  transferSourceSavingId = savingId;
  const saving = state.savings.find(s => s.id === savingId);
  if (!saving) return;

  const select = document.getElementById('transfer-target-currency');
  Array.from(select.options).forEach(opt => {
    opt.disabled = (opt.value === saving.currency);
  });

  openModal('modal-transfer-saving');
}

function submitTransferSaving(e) {
  e.preventDefault();
  const targetCurr = document.getElementById('transfer-target-currency').value;
  const saving = state.savings.find(s => s.id === transferSourceSavingId);
  if (!saving) return;

  if (targetCurr === saving.currency) {
    alert("Farklı bir hedef para birimi seçiniz.");
    return;
  }

  const tryVal = convertToTry(saving.amount, saving.currency);
  const newAmount = convertFromTry(tryVal, targetCurr);

  state.savings = state.savings.filter(s => s.id !== transferSourceSavingId);
  state.savings.push({
    id: Date.now(),
    amount: Math.round(newAmount * 10000) / 10000,
    currency: targetCurr,
    description: `${saving.currency} → ${targetCurr} Çeviri`,
    date: getTodayStr()
  });

  closeModal('modal-transfer-saving');
  renderApp();
  showToast(`${saving.currency} varlığı ${targetCurr} birimine çevrildi`, "🔄");
}

// Currency Selection Modal
function openCurrencySelectModal() {
  const options = ['USD/TL', 'EUR/TL', 'GBP/TL', 'Gram Altın', 'BTC/TL', 'ETH/TL', 'JPY/TL', 'CHF/TL', 'Gümüş', 'CNY/TL'];
  const container = document.getElementById('currency-options-checkboxes');

  container.innerHTML = options.map(opt => `
    <label style="display:flex; align-items:center; gap:8px; font-weight:600; cursor:pointer;">
      <input type="checkbox" value="${opt}" ${state.selectedCurrencies.includes(opt) ? 'checked' : ''}>
      ${opt}
    </label>
  `).join('');

  openModal('modal-currency-select');
}

function submitCurrencySelect() {
  const checked = Array.from(document.querySelectorAll('#currency-options-checkboxes input:checked')).map(i => i.value);
  if (checked.length === 0) {
    alert("En az 1 döviz seçmelisiniz.");
    return;
  }
  state.selectedCurrencies = checked.slice(0, 6);
  // Bug #6 fix: tell the user if their selection was trimmed to the max of 6
  if (checked.length > 6) {
    showToast("En fazla 6 döviz seçilebilir, ilk 6 kaydedildi.", "⚠️");
  }
  closeModal('modal-currency-select');
  renderHomeMarketRates();
  showToast("Döviz görünümü güncellendi", "💱");
}

// Investment Test Modal
function openInvestmentTestModal() {
  openModal('modal-investment-test');
}

function submitInvestmentTest(profile) {
  state.investmentProfile = profile;
  closeModal('modal-investment-test');
  renderWalletInvestment();
  showToast(`Yatırım profiliniz: ${profile.toUpperCase()}`, "📊");
}

function showDayActivities(dateStr) {
  const list = state.activities.filter(a => a.date === dateStr);
  if (list.length === 0) {
    showToast(`${dateStr} tarihinde işlem kaydı yok`, "📅");
    return;
  }
  // Bug #7 fix: use a modal instead of alert()
  const body = list.map(a =>
    `<div style="display:flex;justify-content:space-between;align-items:center;padding:10px 14px;background:white;border-radius:14px;border:1px solid #E2E8F0;margin-bottom:8px;">
       <div>
         <div style="font-size:13px;font-weight:700;">${a.description}</div>
         <div style="font-size:11px;color:var(--gray);">${a.category}</div>
       </div>
       <div style="font-weight:800;font-size:14px;color:${a.type === 'gelir' ? 'var(--green)' : 'var(--coral)'}">
         ${a.type === 'gelir' ? '+' : '-'}${formatTry(a.amount)}
       </div>
     </div>`
  ).join('');

  document.getElementById('goal-detail-title').textContent = `📅 ${dateStr} İşlemleri`;
  document.getElementById('goal-detail-status-badge').textContent = `${list.length} işlem`;
  document.getElementById('goal-detail-status-badge').style.background = 'rgba(99,102,241,0.1)';
  document.getElementById('goal-detail-status-badge').style.color = 'var(--primary)';
  document.getElementById('goal-detail-body').innerHTML =
    `<div style="display:flex;flex-direction:column;gap:0;max-height:320px;overflow-y:auto;">${body}</div>`;
  openModal('modal-goal-detail');
}
