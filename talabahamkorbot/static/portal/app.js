const API_BASE = window.location.hostname === 'localhost' 
    ? 'https://tengdosh.uzjoku.uz/api/v1' 
    : window.location.pathname.includes('/dbs/weto/tengdosh')
        ? '/dbs/weto/tengdosh/api/v1'
        : 'https://tengdosh.uzjoku.uz/api/v1';
const API_KEY = 'LXjqwQE0Xemgq3E7LeB0tn2yMQWY0zXW';

const state = {
    token: localStorage.getItem('auth_token'),
    user: JSON.parse(localStorage.getItem('user_profile') || 'null'),
    currentView: 'login',
    currentTab: 'home',
    scheduleMode: 'daily', // 'daily' or 'weekly'
    selectedDay: new Date().toISOString().split('T')[0]
};

// --- Core Functions ---

function init() {
    if (state.token && state.user) {
        showView('dashboard');
        navigateTo('home');
    } else {
        showView('login');
    }
}

function showView(viewName) {
    const app = document.getElementById('app');
    const template = document.getElementById(`${viewName}-template`);
    
    if (!template) return;
    
    const clone = template.content.cloneNode(true);
    app.innerHTML = '';
    app.appendChild(clone);
    state.currentView = viewName;
    
    if (viewName === 'login') {
        setupLoginForm();
    } else if (viewName === 'dashboard') {
        setupDashboardUI();
    }
}

function setLoading(isLoading) {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
        overlay.style.display = isLoading ? 'flex' : 'none';
    }
}

// --- Navigation ---

function navigateTo(tabId) {
    // Hide all sections
    document.querySelectorAll('.view-section').forEach(s => s.style.display = 'none');
    
    // Show target section
    const section = document.getElementById(`view-${tabId}`);
    if (section) section.style.display = 'block';

    // Update Sidebar
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    const navItem = document.querySelector(`.nav-item[data-view="${tabId}"]`);
    if (navItem) navItem.classList.add('active');

    // Update Title
    const title = document.getElementById('page-title');
    const titles = {
        home: 'Bosh sahifa',
        schedule: 'Dars jadvali',
        grades: 'Baholar',
        attendance: 'Davomat',
        profile: 'Profil'
    };
    title.textContent = titles[tabId] || 'Tengdosh';

    state.currentTab = tabId;

    // Fetch Data for the view
    switch(tabId) {
        case 'home': renderDashboard(); break;
        case 'schedule': renderSchedule(); break;
        case 'grades': renderGrades(); break;
        case 'attendance': renderAttendance(); break;
        case 'profile': renderProfile(); break;
    }
}

// --- Auth Functions ---

async function apiFetch(endpoint, options = {}) {
    const headers = {
        'X-Api-Key': API_KEY,
        'Content-Type': 'application/json',
        ...options.headers
    };
    if (state.token) {
        headers['Authorization'] = `Bearer ${state.token}`;
    }

    const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers
    });

    if (response.status === 401) {
        logout();
        throw new Error("Sessiya muddati tugadi");
    }

    const result = await response.json();
    return result.data || result;
}

async function login(username, password) {
    setLoading(true);
    const errorDiv = document.getElementById('error-message');
    if (errorDiv) errorDiv.style.display = 'none';

    try {
        const data = await apiFetch('/auth/hemis', {
            method: 'POST',
            body: JSON.stringify({ login: username, password: password })
        });

        if (data.token) {
            localStorage.setItem('auth_token', data.token);
            localStorage.setItem('user_profile', JSON.stringify(data.profile));
            state.token = data.token;
            state.user = data.profile;
            
            showView('dashboard');
            navigateTo('home');
        } else {
            throw new Error("Ma'lumotlar olinmadi");
        }
    } catch (error) {
        if (errorDiv) {
            errorDiv.textContent = error.message;
            errorDiv.style.display = 'block';
        }
    } finally {
        setLoading(false);
    }
}

function logout() {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('user_profile');
    state.token = null;
    state.user = null;
    showView('login');
}

// --- UI Setup ---

function setupLoginForm() {
    const form = document.getElementById('login-form');
    if (form) {
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            const loginVal = document.getElementById('login').value;
            const passVal = document.getElementById('password').value;
            login(loginVal, passVal);
        });
    }
}

function setupDashboardUI() {
    document.querySelectorAll('.nav-item[data-view]').forEach(item => {
        item.addEventListener('click', () => {
            navigateTo(item.getAttribute('data-view'));
        });
    });

    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) logoutBtn.addEventListener('click', logout);

    if (state.user) {
        const userNameEl = document.getElementById('user-name');
        if (userNameEl) userNameEl.textContent = state.user.full_name || 'Talaba';
        
        const avatar = document.getElementById('user-avatar');
        if (avatar) {
            if (state.user.image) {
                avatar.innerHTML = `<img src="${state.user.image}" alt="User">`;
            } else {
                avatar.textContent = (state.user.full_name || 'T')[0];
            }
        }
    }

    // Schedule Mode Toggles
    const modeBtns = document.querySelectorAll('.tab-btn[data-mode]');
    modeBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            modeBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            state.scheduleMode = btn.getAttribute('data-mode');
            renderSchedule();
        });
    });
}

// --- Data Rendering ---

async function renderDashboard() {
    try {
        setLoading(true);
        const data = await apiFetch('/student/dashboard/');
        
        document.getElementById('stat-gpa').textContent = data.gpa || '0.0';
        document.getElementById('stat-attendance').textContent = `${data.attendance_percentage || 0}%`;
        document.getElementById('stat-messages').textContent = data.notification_count || 0;
        
        const classesContainer = document.getElementById('today-classes');
        if (data.today_lessons && data.today_lessons.length > 0) {
            classesContainer.innerHTML = data.today_lessons.map(lesson => renderLessonCard(lesson)).join('');
        } else {
            classesContainer.innerHTML = '<p style="color: #888; text-align: center; padding: 2rem;">Bugun darslar yo\'q 🎉</p>';
        }
    } catch (e) {
        console.error(e);
    } finally {
        setLoading(false);
    }
}

async function renderSchedule() {
    try {
        setLoading(true);
        const scheduleList = document.getElementById('schedule-list');
        const daySelector = document.getElementById('day-selector');
        
        // Hide/Show Day Selector based on mode
        daySelector.style.display = state.scheduleMode === 'daily' ? 'flex' : 'none';

        if (state.scheduleMode === 'daily') {
            // Render Day Selector (this week)
            const days = getWeekDays();
            daySelector.innerHTML = days.map(day => `
                <div class="day-chip ${day.date === state.selectedDay ? 'active' : ''}" onclick="app.selectDay('${day.date}')">
                    <span class="day-name">${day.shortName}</span>
                    <span class="day-num">${day.num}</span>
                </div>
            `).join('');

            const data = await apiFetch(`/education/schedule?date=${state.selectedDay}`);
            if (data && data.length > 0) {
                scheduleList.innerHTML = data.map(lesson => renderLessonCard(lesson)).join('');
            } else {
                scheduleList.innerHTML = '<div class="card" style="text-align: center; padding: 3rem; color: #888;">Bu kunda darslar topilmadi</div>';
            }
        } else {
            // Weekly Mode
            const data = await apiFetch('/education/schedule?mode=weekly');
            // Backend usually returns grouped by day
            if (data && Object.keys(data).length > 0) {
                scheduleList.innerHTML = Object.entries(data).map(([day, lessons]) => `
                    <h3 style="margin: 1.5rem 0 1rem; color: var(--text-black);">${day}</h3>
                    ${lessons.map(l => renderLessonCard(l)).join('')}
                `).join('');
            } else {
                 scheduleList.innerHTML = '<div class="card" style="text-align: center; padding: 3rem; color: #888;">Haftalik jadval yuklanmadi</div>';
            }
        }
    } catch (e) {
        console.error(e);
    } finally {
        setLoading(false);
    }
}

async function renderGrades() {
    try {
        setLoading(true);
        const data = await apiFetch('/education/grades');
        const tbody = document.getElementById('grades-table-body');
        
        if (data && data.length > 0) {
            tbody.innerHTML = data.map(item => `
                <tr>
                    <td style="font-weight: 600;">${item.subject}</td>
                    <td><span style="font-size: 0.8rem; background: #eee; padding: 2px 8px; border-radius: 4px;">${item.lesson_type || 'Ma\'ruza'}</span></td>
                    <td style="color: var(--primary-blue); font-weight: 700;">${item.grade_value || '-'}</td>
                    <td><b style="color: ${item.grade_name === 'A' ? 'var(--accent-green)' : 'inherit'}">${item.grade_name || '-'}</b></td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; padding: 2rem; color: #888;">Ma\'lumot topilmadi</td></tr>';
        }
    } catch (e) {
        console.error(e);
    } finally {
        setLoading(false);
    }
}

async function renderAttendance() {
    try {
        setLoading(true);
        const data = await apiFetch('/education/attendance');
        const tbody = document.getElementById('attendance-table-body');
        
        if (data && data.items) {
            tbody.innerHTML = data.items.map(item => `
                <tr>
                    <td>${item.date}</td>
                    <td>${item.subject}</td>
                    <td>
                        <span style="color: ${item.status === 'present' ? 'var(--accent-green)' : 'var(--error-red)'}; font-weight: 600;">
                            ${item.status === 'present' ? '✅ Kelgan' : '❌ Kelmagan'}
                        </span>
                    </td>
                    <td style="font-size: 0.8rem; color: #888;">${item.reason || '-'}</td>
                </tr>
            `).join('');
        }
    } catch (e) {
        console.error(e);
    } finally {
        setLoading(false);
    }
}

function renderProfile() {
    if (!state.user) return;
    
    document.getElementById('profile-full-name').textContent = state.user.full_name || 'Noma\'lum';
    document.getElementById('profile-id').textContent = `ID: ${state.user.hemis_id || '-'}`;
    
    const list = document.getElementById('profile-details-list');
    const fields = [
        { label: 'Universitet', value: state.user.university },
        { label: 'Fakultet', value: state.user.faculty },
        { label: 'Yo\'nalish', value: state.user.specialty },
        { label: 'Guruh', value: state.user.group },
        { label: 'Kurs', value: state.user.level },
        { label: 'Telefon', value: state.user.phone }
    ];
    
    list.innerHTML = fields.map(f => `
        <div style="display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid #f5f5f5;">
            <span style="color: #888;">${f.label}</span>
            <span style="font-weight: 500;">${f.value || '-'}</span>
        </div>
    `).join('');
}

// --- Helpers ---

function renderLessonCard(lesson) {
    return `
        <div class="lesson-card">
            <div class="lesson-time">
                ${lesson.pair_start_time}<br>
                <span style="font-weight: 400; font-size: 0.7rem; color: #888;">${lesson.pair_end_time}</span>
            </div>
            <div class="lesson-info">
                <h3>${lesson.subject}</h3>
                <div class="lesson-meta">
                    <span>📍 ${lesson.auditorium}</span>
                    <span>👤 ${lesson.employee}</span>
                    <span>📝 ${lesson.lesson_type}</span>
                </div>
            </div>
        </div>
    `;
}

function getWeekDays() {
    const days = [];
    const now = new Date();
    const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay() + 1));
    
    const names = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    
    for (let i = 0; i < 7; i++) {
        const d = new Date(startOfWeek);
        d.setDate(d.getDate() + i);
        const dateStr = d.toISOString().split('T')[0];
        days.push({
            shortName: names[i],
            num: d.getDate(),
            date: dateStr
        });
    }
    return days;
}

// Export functions for global access in HTML
window.app = {
    navigateTo,
    selectDay: (date) => {
        state.selectedDay = date;
        renderSchedule();
    }
};

// Start the app
init();
