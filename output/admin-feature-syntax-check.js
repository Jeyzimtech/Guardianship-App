

        let usersList = [];
        let teachersList = [];
        let studentsList = [];
        let schoolsList = [];
        let classesList = [];
        let announcementsList = [];
        let directoryList = [];
        let uniformsList = [];
        let reportsList = [];
        let journalFeedList = [];
        let attendanceRosterList = [];
        let activeRoleFilter = 'all';
        let academicYearsList = [];

        // API Helper with Token Injection
        async function apiFetch(endpoint, options = {}) {
            const token = localStorage.getItem('admin_token');
            const headers = {
                'Accept': 'application/json',
                ...(options.headers || {})
            };
            if (!(options.body instanceof FormData)) {
                headers['Content-Type'] = 'application/json';
            }
            if (token) {
                headers['Authorization'] = 'Bearer ' + token;
            }
            try {
                const res = await fetch(endpoint, { ...options, headers });
                const data = await res.json().catch(() => ({}));
                if (res.status === 401) {
                    localStorage.removeItem('admin_token');
                    localStorage.removeItem('admin_user');
                    document.getElementById('authScreen').classList.remove('hidden');
                }
                return { ok: res.ok, status: res.status, data };
            } catch (err) {
                console.warn('API error at ' + endpoint, err);
                return { ok: false, status: 0, data: { message: err.message } };
            }
        }

        // Keep the login form visible when the session is cleared.
        function switchAuthTab(tab) {
            document.getElementById('tabBtnLogin')?.classList.toggle('active', tab === 'login');
            document.getElementById('tabBtnSignup')?.classList.toggle('active', tab === 'signup');
            document.getElementById('loginForm')?.classList.toggle('active', tab === 'login');
            document.getElementById('signupForm')?.classList.toggle('active', tab === 'signup');
        }

        async function handleLoginSubmit(e) {
            e.preventDefault();
            const usernameOrEmail = document.getElementById('loginEmail').value.trim();
            const password = document.getElementById('loginPassword').value;
            const btn = e.target.querySelector('button[type="submit"]');
            const originalText = btn.innerText;
            btn.innerText = 'LOGGING IN...';
            btn.disabled = true;

            try {
                const res = await apiFetch('/api/auth/login', {
                    method: 'POST',
                    body: JSON.stringify({ email: usernameOrEmail, username: usernameOrEmail, password })
                });

                if (res.ok && res.data.status === 'success' && ['admin', 'website_admin'].includes(res.data.user?.role)) {
                    localStorage.setItem('admin_token', res.data.token);
                    localStorage.setItem('admin_user', JSON.stringify(res.data.user));

                    const name = res.data.user.name || 'Administrator';
                    document.getElementById('headerAdminName').innerText = name;
                document.getElementById('headerAdminRole').innerText = res.data.user.role === 'website_admin' ? 'Platform Owner' : 'School Admin';
                    document.getElementById('headerAvatar').innerText = name.split(' ').map(n=>n[0]).join('').substring(0, 2).toUpperCase();

                    document.getElementById('authScreen').classList.add('hidden');
                    await loadAllDashboardData();
                } else {
                    if (res.ok) { localStorage.removeItem('admin_token'); localStorage.removeItem('admin_user'); }
                    alert(res.ok ? 'This account does not have admin portal access.' : (res.data.message || 'Login failed. Please check your credentials.'));
                }
            } catch (err) {
                alert('Connection error. Please try again.');
            } finally {
                btn.innerText = originalText;
                btn.disabled = false;
            }
        }

        async function requestPasswordReset(event) {
            event.preventDefault();
            const email = document.getElementById('loginEmail').value.trim();
            if (!email) { alert('Enter your account email first, then choose Forgot password.'); document.getElementById('loginEmail').focus(); return false; }
            const res = await apiFetch('/api/auth/forgot-password', { method: 'POST', body: JSON.stringify({ email }) });
            alert(res.data.message || (res.ok ? 'Password reset link sent.' : 'Could not send the reset link.'));
            return false;
        }

        async function handleLogout() {
            if (confirm('Are you sure you want to log out of the Admin Portal?')) {
                try {
                    await apiFetch('/api/auth/logout', { method: 'POST' });
                } catch (_) {}
                localStorage.removeItem('admin_token');
                localStorage.removeItem('admin_user');
                if (document.getElementById('loginForm')) document.getElementById('loginForm').reset();
                switchAuthTab('login');
                document.getElementById('authScreen').classList.remove('hidden');
            }
        }

        // MOBILE SIDEBAR DRAWER
        function toggleSidebar(open) {
            const shouldOpen = typeof open === 'boolean' ? open : !document.body.classList.contains('nav-open');
            document.body.classList.toggle('nav-open', shouldOpen);
            document.querySelector('.menu-toggle')?.setAttribute('aria-expanded', String(shouldOpen));
        }

        document.addEventListener('keydown', e => {
            if (e.key === 'Escape') toggleSidebar(false);
        });

        window.matchMedia('(min-width: 901px)').addEventListener('change', e => {
            if (e.matches) toggleSidebar(false);
        });

        // TAB NAVIGATION
        function switchTab(tabId) {
            const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
            const requestedPane = document.getElementById('tab-' + tabId);
            if (!requestedPane) return;
            const allowedRoles = requestedPane.dataset.roles;
            if (allowedRoles && !allowedRoles.split(',').includes(currentUser.role)) {
                alert('This section is not available for your account role.');
                return;
            }
            document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));

            const targetNav = Array.from(document.querySelectorAll('.nav-link')).find(el => {
                const attr = el.getAttribute('onclick');
                return attr && attr.includes(tabId);
            });
            if (targetNav) targetNav.classList.add('active');

            const targetPane = document.getElementById('tab-' + tabId);
            if (targetPane) targetPane.classList.add('active');
            toggleSidebar(false);
            window.scrollTo(0, 0);
            const loaders = {
                schools: () => Promise.all([loadSchools(), loadClasses(), loadAcademicYears()]),
                announcements: loadAnnouncements,
                activities: loadActivities,
                documents: loadSchoolDocuments,
                behaviour: loadBehaviourCategories
            };
            if (loaders[tabId]) loaders[tabId]();
        }

        function updateSchool(schoolName) {
            const el = document.getElementById('displaySchoolName');
            if (el) el.innerText = schoolName;
        }

        // DATA LOADERS FROM REAL DATABASE
        async function loadAllDashboardData() {
            const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
            document.querySelectorAll('.nav-item[data-roles]').forEach(item => {
                const allowed = item.dataset.roles.split(',');
                item.style.display = allowed.includes(currentUser.role) ? '' : 'none';
            });
            document.querySelectorAll('.tab-pane[data-roles]').forEach(pane => {
                pane.style.display = pane.dataset.roles.split(',').includes(currentUser.role) ? '' : 'none';
            });
            document.querySelectorAll('[data-roles]').forEach(control => {
                control.style.display = control.dataset.roles.split(',').includes(currentUser.role) ? '' : 'none';
            });
            const landingTab = currentUser.role === 'website_admin' ? 'platform' : 'dashboard';
            if (currentUser.role === 'teacher') switchTab('attendance');
            else if (currentUser.role === 'website_admin') switchTab('platform');
            else switchTab(landingTab);
            let loaders = [];
            if (currentUser.role === 'website_admin') {
                loaders = [loadSchools(), loadPlatformDirectory()];
            } else if (currentUser.role === 'admin') {
                loaders = [loadAdminStats(), loadTeachers(), loadStudents(), loadSchools(), loadClasses(), loadAcademicYears(), loadAnnouncements(), loadReports(), loadUniforms()];
            } else if (currentUser.role === 'teacher') {
                loaders = [loadStudents(), loadClasses(), loadAnnouncements(), loadAttendanceRoster(), loadJournalFeed(), loadReports()];
            }
            await Promise.all(loaders);
            if (currentUser.role === 'admin') recalculateStatistics();
        }

        // ACTIVITY ROSTERS
        let activeActivityId = null;
        let activityRosterList = [];

        async function loadActivities() {
            const body = document.getElementById('activitiesTableBody');
            if (!body) return;
            const res = await apiFetch('/api/activities');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load activities.')}</td></tr>`;
                return;
            }
            const activities = res.data.activities || [];
            body.innerHTML = activities.length ? activities.map(a => `<tr><td><strong>${escapeTableText(a.title)}</strong><br><small>${escapeTableText(a.description || '')}</small></td><td>${escapeTableText(String(a.activity_date || '').slice(0, 10))}</td><td>${a.roster_count}</td><td>${a.participated_count}</td><td><button class="btn-sm" onclick="openActivityRoster(${a.id})">Roster</button> <button class="btn-sm" onclick="deleteActivity(${a.id})">Delete</button></td></tr>`).join('')
                : '<tr><td colspan="5" style="text-align:center;padding:20px;">No activities yet.</td></tr>';
        }

        async function addActivitySubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/activities', { method: 'POST', body: JSON.stringify({
                title: document.getElementById('activityTitle').value.trim(),
                activity_date: document.getElementById('activityDate').value,
                description: document.getElementById('activityDescription').value.trim() || null
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not create activity.'); return; }
            event.target.reset();
            await loadActivities();
            openActivityRoster(res.data.activity.id);
        }

        async function openActivityRoster(id) {
            const res = await apiFetch(`/api/activities/${id}/roster`);
            if (!res.ok) { alert(res.data.message || 'Could not load roster.'); return; }
            activeActivityId = id;
            activityRosterList = res.data.roster || [];
            document.getElementById('activityRosterTitle').innerText = `Roster · ${res.data.activity?.title || ''}`;
            document.getElementById('activityRosterCard').style.display = '';
            const options = [['', 'Not on roster'], ['present', 'Took part'], ['late', 'Late'], ['absent', 'Absent']];
            document.getElementById('activityRosterBody').innerHTML = activityRosterList.length ? activityRosterList.map(s => {
                const current = s.status || (s.on_roster ? 'present' : '');
                return `<tr><td>${escapeTableText(s.name)}</td><td>${escapeTableText(s.grade)} ${escapeTableText(s.class_name)}</td><td><select class="form-control" id="activityStatus${s.student_id}" style="max-width:180px;">${options.map(([v, l]) => `<option value="${v}" ${v === current ? 'selected' : ''}>${l}</option>`).join('')}</select></td></tr>`;
            }).join('') : '<tr><td colspan="3" style="text-align:center;padding:20px;">No students enrolled.</td></tr>';
        }

        async function saveActivityRoster() {
            if (!activeActivityId) return;
            const records = activityRosterList
                .map(s => ({ student_id: s.student_id, status: document.getElementById(`activityStatus${s.student_id}`)?.value || null, was: s.on_roster }))
                .filter(r => r.status || r.was)
                .map(({ student_id, status }) => ({ student_id, status }));
            if (!records.length) { alert('Choose at least one learner.'); return; }
            const res = await apiFetch(`/api/activities/${activeActivityId}/roster`, { method: 'POST', body: JSON.stringify({ records }) });
            alert(res.data?.message || (res.ok ? 'Roster saved.' : 'Could not save roster.'));
            if (res.ok) await loadActivities();
        }

        async function deleteActivity(id) {
            if (!confirm('Delete this activity and its roster?')) return;
            const res = await apiFetch(`/api/activities/${id}`, { method: 'DELETE' });
            if (!res.ok) { alert(res.data.message || 'Could not delete activity.'); return; }
            if (activeActivityId === id) document.getElementById('activityRosterCard').style.display = 'none';
            await loadActivities();
        }

        // BEHAVIOUR CATEGORIES
        async function loadBehaviourCategories() {
            const body = document.getElementById('behaviourCategoriesBody');
            if (!body) return;
            const res = await apiFetch('/api/behaviour-categories');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="3" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load categories.')}</td></tr>`;
                return;
            }
            const categories = res.data.categories || [];
            body.innerHTML = categories.length ? categories.map(c => `<tr><td>${escapeTableText(c.name)}</td><td><span class="role-badge ${c.polarity === 'positive' ? 'teacher' : 'guardian'}">${c.polarity === 'positive' ? 'Merit' : 'Conduct note'}</span></td><td><button class="btn-sm" onclick="deleteBehaviourCategory(${c.id})">Remove</button></td></tr>`).join('')
                : '<tr><td colspan="3" style="text-align:center;padding:20px;">No categories yet. Teachers can log any category until you add some.</td></tr>';
        }

        async function addBehaviourCategorySubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/behaviour-categories', { method: 'POST', body: JSON.stringify({
                name: document.getElementById('behaviourCategoryName').value.trim(),
                polarity: document.getElementById('behaviourCategoryPolarity').value
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not add category.'); return; }
            event.target.reset();
            await loadBehaviourCategories();
        }

        async function deleteBehaviourCategory(id) {
            if (!confirm('Remove this behaviour category?')) return;
            const res = await apiFetch(`/api/behaviour-categories/${id}`, { method: 'DELETE' });
            if (!res.ok) { alert(res.data.message || 'Could not remove category.'); return; }
            await loadBehaviourCategories();
        }

        async function loadAdminStats() {
            const res = await apiFetch('/api/admin/dashboard-stats');
            if (res.ok && res.data.stats) {
                const s = res.data.stats;
                const kpiStu = document.getElementById('kpiStudents');
                if (kpiStu) kpiStu.innerText = s.total_students.toLocaleString();
                const kpiAtt = document.getElementById('kpiAttendanceRate');
                if (kpiAtt) kpiAtt.innerText = s.attendance_rate + '%';
                const kpiTeach = document.getElementById('kpiTeachers');
                if (kpiTeach) kpiTeach.innerText = s.active_teachers.toLocaleString();
                const kpiCls = document.getElementById('kpiClasses');
                if (kpiCls) kpiCls.innerText = s.total_classes.toLocaleString();
                const schCount = document.getElementById('platformSchoolCount');
                if (schCount) schCount.innerText = s.total_schools.toLocaleString();
                const actSub = document.getElementById('platformActiveSubs');
                if (actSub) actSub.innerText = s.active_subscriptions.toLocaleString();
                const suspSub = document.getElementById('platformSuspendedSubs');
                if (suspSub) suspSub.innerText = s.suspended_subscriptions.toLocaleString();
                if (s.charts) initDashboardCharts(s.charts);
            }
        }

        async function loadUsers() {
            const res = await apiFetch('/api/users');
            if (res.ok && res.data.users) {
                usersList = res.data.users;
            }
            const guardianSelect = document.getElementById('linkGuardianId');
            if (guardianSelect) guardianSelect.innerHTML = '<option value="">Choose guardian</option>' + usersList.filter(u => u.role === 'guardian').map(u => `<option value="${u.id}">${u.name} (${u.email || u.phone_number || 'No contact'})</option>`).join('');
            renderUsersTable();
        }

        async function loadTeachers() {
            const res = await apiFetch('/api/teachers');
            if (res.ok && res.data.teachers) {
                teachersList = res.data.teachers;
            }
            renderTeachersTable();
            const el = document.getElementById('kpiTeachers');
            if (el) el.innerText = teachersList.length.toString();
        }

        async function loadStudents() {
            const res = await apiFetch('/api/students');
            if (res.ok && res.data.students) {
                studentsList = res.data.students;

                // Populate student selects in Journal and Report modals
                const journalSelect = document.getElementById('journalStudentId');
                if (journalSelect) {
                    journalSelect.innerHTML = '<option value="">-- Select Enrolled Student --</option>' +
                        studentsList.map(s => `<option value="${s.id}">${s.name} (${s.class_name || s.grade || 'Student'})</option>`).join('');
                }
                const repSelect = document.getElementById('repStudentId');
                if (repSelect) {
                    repSelect.innerHTML = '<option value="">-- Choose Student --</option>' +
                        studentsList.map(s => `<option value="${s.id}">${s.name} (${s.class_name || s.grade || 'Student'})</option>`).join('');
                }

                // Populate class select in Attendance register
                const attClassSelect = document.getElementById('attClassSelect');
                if (attClassSelect) {
                    const classes = [...new Set(studentsList.map(s => s.class_name).filter(Boolean))];
                    attClassSelect.innerHTML = '<option value="all">All Classes</option>' +
                        classes.map(c => `<option value="${c}">${c}</option>`).join('');
                }
                const linkStudentSelect = document.getElementById('linkStudentId');
                if (linkStudentSelect) linkStudentSelect.innerHTML = '<option value="">Choose student</option>' + studentsList.map(s => `<option value="${s.id}">${s.name} (${s.class_name || s.grade || 'Student'})</option>`).join('');
            }
            renderStudentsTable();
            const el = document.getElementById('kpiStudents');
            if (el) el.innerText = studentsList.length.toString();
        }

        async function loadFeeAccounts() {
            const body = document.getElementById('feeAccountsBody');
            if (!body) return;
            const res = await apiFetch('/api/fees/accounts');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load fee accounts.')}</td></tr>`;
                return;
            }
            await loadPendingPayments();
            const accounts = res.data.accounts || [];
            body.innerHTML = accounts.length ? accounts.map(account => `<tr><td>${escapeTableText(account.name)}</td><td>${escapeTableText(account.grade)} ${escapeTableText(account.class_name)}</td><td><input class="form-control" type="number" min="0" step="0.01" id="feeUsd${account.student_id}" value="${account.balance_usd}" style="max-width:140px;"></td><td><input class="form-control" type="number" min="0" step="0.01" id="feeZig${account.student_id}" value="${account.balance_zig}" style="max-width:140px;"></td><td><button class="btn-sm" onclick="saveFeeAccount(${account.student_id})">Save balances</button></td></tr>`).join('') : '<tr><td colspan="5" style="text-align:center;padding:20px;">No students enrolled at this school.</td></tr>';
        }

        async function loadPendingPayments() {
            let section = document.getElementById('pendingPaymentSection');
            if (!section) {
                section = document.createElement('div'); section.id = 'pendingPaymentSection';
                document.getElementById('feeAccountsBody')?.closest('.table-card')?.after(section);
            }
            const [fees, uniforms] = await Promise.all([apiFetch('/api/fees/payments/pending'), apiFetch('/api/uniform-payments/pending')]);
            if (!fees.ok || !uniforms.ok) { section.textContent = 'Could not load payments awaiting verification.'; return; }
            const rows = [
                ...(fees.data.payments || []).map(p => ({kind:'fee', id:p.id, name:p.fee_account?.student?.name, amount:p.amount, currency:p.currency, method:p.payment_method, reference:p.reference, has_proof:p.has_proof})),
                ...(uniforms.data.orders || []).map(p => ({kind:'uniform', id:p.id, name:p.student?.name, amount:p.total_amount, currency:p.currency, method:p.payment_method, reference:p.payment_reference}))
            ];
            section.innerHTML = `<h3 class="section-title" style="margin-top:24px;">Payments awaiting verification</h3><p>Verify each reference against the actual payment received before confirming.</p><div class="table-card"><table class="data-table"><thead><tr><th>Student</th><th>For</th><th>Amount</th><th>Reference</th><th>Action</th></tr></thead><tbody>${rows.length ? rows.map(p => `<tr><td>${escapeTableText(p.name)}</td><td>${p.kind === 'fee' ? 'School fees' : 'Uniform order'}</td><td>${escapeTableText(p.currency)} ${escapeTableText(p.amount)}</td><td>${escapeTableText(p.method)} / ${escapeTableText(p.reference)}</td><td>${p.kind === 'fee' && p.has_proof ? `<button class="btn-sm" onclick="downloadPaymentProof(${Number(p.id)})">View proof</button> ` : ''}<button class="btn-sm" onclick="verifySchoolPayment('${p.kind}',${Number(p.id)})">Confirm received payment</button></td></tr>`).join('') : '<tr><td colspan="5">No payment references awaiting verification.</td></tr>'}</tbody></table></div>`;
        }
        async function downloadPaymentProof(id) {
            try {
                const response = await fetch(`/api/fees/payments/${id}/proof`, {headers:{Authorization:`Bearer ${localStorage.getItem('admin_token') || ''}`}});
                if (!response.ok) throw new Error('Could not load payment proof.');
                const blob = await response.blob();
                const url = URL.createObjectURL(blob);
                const link = document.createElement('a'); link.href = url; link.download = 'payment-proof-' + id;
                document.body.appendChild(link); link.click(); link.remove(); setTimeout(() => URL.revokeObjectURL(url), 60000);
            } catch (error) { alert(error.message); }
        }
        async function verifySchoolPayment(kind, id) {
            if (!confirm('Have you verified this reference and amount against funds actually received by the school?')) return;
            const endpoint = kind === 'fee' ? `/api/fees/payments/${id}/verify` : `/api/uniform-orders/${id}/verify-payment`;
            const res = await apiFetch(endpoint, {method:'POST', body:JSON.stringify({confirmed:true})});
            alert(res.data?.message || (res.ok ? 'Payment verified.' : 'Could not verify payment.'));
            if (res.ok) await loadFeeAccounts();
        }

        async function saveFeeAccount(studentId) {
            const payload = {
                student_id: studentId,
                balance_usd: Number(document.getElementById(`feeUsd${studentId}`)?.value),
                balance_zig: Number(document.getElementById(`feeZig${studentId}`)?.value)
            };
            const res = await apiFetch('/api/fees/update-balance', { method: 'POST', body: JSON.stringify(payload) });
            alert(res.data?.message || (res.ok ? 'Fee account saved.' : 'Could not update fee account.'));
            if (res.ok) await loadFeeAccounts();
        }

        function escapeTableText(value) {
            return String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
        }

        async function loadStudentLinkRequests() {
            const body = document.getElementById('studentLinkRequestsBody');
            if (!body) return;
            const res = await apiFetch('/api/students/link-requests');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load requests.')}</td></tr>`;
                return;
            }
            const requests = res.data.requests || [];
            if (!requests.length) {
                body.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;color:var(--text-secondary);">No pending guardian requests.</td></tr>';
                return;
            }
            body.innerHTML = requests.map(request => {
                const candidates = studentsList.filter(student => student.name?.trim().toLowerCase() === request.student_name.trim().toLowerCase()
                    && (!request.school_name || student.school?.name?.trim().toLowerCase() === request.school_name.trim().toLowerCase()));
                const choice = `<select class="form-control" id="linkRequestStudent${request.id}"><option value="">Select matching student</option>${candidates.map(student => `<option value="${student.id}">${escapeTableText(student.name)} · ${escapeTableText(student.class_name || student.grade || 'Student')}</option>`).join('')}</select>`;
                return `<tr><td>${escapeTableText(request.guardian_name)}<br><small>${escapeTableText(request.guardian_email)}</small></td><td>${escapeTableText(request.student_name)}</td><td>${escapeTableText(request.school_name || 'Any school')}</td><td>${escapeTableText(request.relationship || 'Guardian')}<br><small>${escapeTableText(request.notes || '')}</small></td><td>${choice}<button class="btn-sm" style="margin-top:6px;" onclick="reviewStudentLinkRequest(${request.id}, 'approve')" ${candidates.length ? '' : 'disabled'}>Approve & Link</button> <button class="btn-sm" style="margin-top:6px;" onclick="reviewStudentLinkRequest(${request.id}, 'reject')">Reject</button></td></tr>`;
            }).join('');
        }

        async function reviewStudentLinkRequest(id, decision) {
            const payload = { decision };
            if (decision === 'approve') {
                payload.student_id = document.getElementById(`linkRequestStudent${id}`)?.value;
                if (!payload.student_id) return alert('Choose the matching student before approving.');
            }
            const res = await apiFetch(`/api/students/link-requests/${id}/review`, { method: 'POST', body: JSON.stringify(payload) });
            alert(res.data?.message || (res.ok ? 'Request updated.' : 'Could not update request.'));
            if (res.ok) await loadStudentLinkRequests();
        }

        async function loadSchools() {
            const res = await apiFetch('/api/schools');
            if (res.ok && res.data.schools) {
                schoolsList = res.data.schools;

                const uniSchoolSelect = document.getElementById('uniSchoolId');
                if (uniSchoolSelect) {
                    uniSchoolSelect.innerHTML = '<option value="">All Schools</option>' +
                        schoolsList.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
                }
                ['classSchoolId', 'tSchoolId', 'annSchoolId'].forEach(id => {
                    const select = document.getElementById(id);
                    if (select) select.innerHTML = '<option value="">Select school</option>' + schoolsList.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
                });
                const countEl = document.getElementById('platformSchoolCount');
                if (countEl) countEl.innerText = schoolsList.length.toString();
                if (schoolsList.length > 0) updateSchool(schoolsList[0].name);
                const platformSchoolFilter = document.getElementById('platformSchoolFilter');
                if (platformSchoolFilter) {
                    const previous = platformSchoolFilter.value || 'all';
                    platformSchoolFilter.innerHTML = '<option value="all">All schools</option>' + schoolsList.map(s => `<option value="${s.id}">${escapeTableText(s.name)}</option>`).join('');
                    platformSchoolFilter.value = schoolsList.some(s => String(s.id) === previous) ? previous : 'all';
                    renderPlatformSchoolTabs(platformSchoolFilter.value);
                }

                const dirBody = document.getElementById('platformDirectoryBody');
                if (dirBody) {
                    dirBody.innerHTML = schoolsList.map(s => `
                        <tr>
                            <td><strong>${escapeTableText(s.name)}</strong></td>
                            <td><span class="badge" style="color:#1E40AF;">${escapeTableText((s.type || 'primary').toUpperCase())}</span></td>
                            <td>${escapeTableText(s.primary_admin_name || 'Not assigned')}${s.primary_admin_email ? ` (${escapeTableText(s.primary_admin_email)})` : ''}</td>
                            <td><span style="display:inline-block; width:14px; height:14px; background:${escapeTableText(s.branding_color || '#3B5998')}; border-radius:50%; vertical-align:middle; margin-right:4px;"></span> ${escapeTableText(s.branding_color || '#3B5998')}</td>
                            <td>${Number(s.students_count || 0)} Children</td>
                            <td><button class="btn-sm" onclick="filterPlatformStudents(${s.id})">View Students</button> <button class="btn-sm" style="color:var(--danger-red);" onclick="removePlatformSchool(${s.id})">Remove school</button></td>
                        </tr>
                    `).join('');
                }
            }
        }

        async function removePlatformSchool(id) {
            const school = schoolsList.find(s => s.id === id);
            if (!school || currentUser.role !== 'website_admin') return;
            const typed = prompt(`Permanently remove ${school.name}? This wipes children, registers, documents, payments and school staff accounts. Parents linked to other schools keep those accounts. Type the school name to continue.`);
            if (typed === null) return;
            if (typed !== school.name) { alert('School name does not match.'); return; }
            const res = await apiFetch(`/api/platform/schools/${id}`, {method:'DELETE', body:JSON.stringify({confirm_name:typed})});
            alert(res.data?.message || (res.ok ? 'School removed.' : 'Could not remove school.'));
            if (res.ok) { await loadSchools(); await loadPlatformDirectory(); }
        }

        async function loadClasses() {
            const res = await apiFetch('/api/school-classes');
            if (res.ok && res.data.school_classes) {
                classesList = res.data.school_classes;
                const newUserClass = document.getElementById('newUserClass');
                if (newUserClass) {
                    const selected = newUserClass.value;
                    newUserClass.innerHTML = '<option value="">Select a class</option>' + classesList.map(c => `<option value="${c.id}">${escapeTableText(c.grade)} - ${escapeTableText(c.class_name)}</option>`).join('');
                    newUserClass.value = selected;
                }
                renderTeachersTable();
                const classSelect = document.getElementById('sClass');
                if (classSelect) {
                    classSelect.innerHTML = '<option value="">Select assigned class</option>' + classesList.map(c => `<option value="${c.id}">${c.class_name} (${c.grade})</option>`).join('');
                }
                const teacherClassSelect = document.getElementById('tClass');
                if (teacherClassSelect) teacherClassSelect.innerHTML = '<option value="">Select class</option>' + classesList.map(c => `<option value="${c.class_name}" data-school="${c.school_id}">${c.class_name} (${c.grade})</option>`).join('');
                const countEl = document.getElementById('kpiClasses');
                if (countEl) countEl.innerText = classesList.length.toString();

                const classesTbody = document.getElementById('classesTableBody');
                if (classesTbody) {
                    classesTbody.innerHTML = classesList.length ? classesList.map(c => {
                        const teachers = (c.teacher_list || []).map(t => `${escapeTableText(t.name || 'Teacher')} <small>(${escapeTableText(t.subject || 'Homeroom')})</small>`).join('<br>');
                        return `
                        <tr>
                            <td><strong>${escapeTableText(c.class_name)}</strong></td>
                            <td>${escapeTableText(c.grade || 'Primary')}</td>
                            <td>${teachers || '<span style="color:var(--text-secondary);">No teacher assigned</span>'}</td>
                            <td>${c.student_count ?? 0}${c.capacity ? ` / ${c.capacity}` : ''} Students</td>
                            <td><button class="btn-sm" onclick="openClassRoster(${c.id})">Roster</button> <button class="btn-sm" onclick="editClass(${c.id})">Edit</button> <button class="btn-sm" onclick="deleteClass(${c.id})">Delete</button></td>
                        </tr>`;
                    }).join('') : '<tr><td colspan="5" style="text-align:center;padding:20px;">No classes configured</td></tr>';
                }
            }
        }

        function openClassRoster(id) {
            const c = classesList.find(x => x.id === id);
            if (!c) return;
            document.getElementById('classRosterTitle').innerText = `Roster · ${c.grade} - ${c.class_name} (${c.student_count ?? 0} students)`;
            document.getElementById('classRosterBody').innerHTML = (c.roster || []).length
                ? c.roster.map(s => `<tr><td>${escapeTableText(s.name)}</td><td>${s.guardians_count || 0}</td></tr>`).join('')
                : '<tr><td colspan="2" style="text-align:center;padding:20px;">No students enrolled in this class yet.</td></tr>';
            document.getElementById('classRosterCard').style.display = '';
        }

        async function editClass(id) {
            const c = classesList.find(x => x.id === id);
            if (!c) return;
            const grade = prompt('Grade level', c.grade || '');
            if (grade === null) return;
            const className = prompt('Class name', c.class_name || '');
            if (className === null) return;
            const capacity = prompt('Capacity', c.capacity || 30);
            if (capacity === null) return;
            const res = await apiFetch(`/api/school-classes/${id}`, { method: 'PUT', body: JSON.stringify({ grade: grade.trim(), class_name: className.trim(), capacity: Number(capacity) || null }) });
            if (!res.ok) { alert(res.data.message || 'Could not update class.'); return; }
            await loadClasses(); await loadStudents();
        }

        async function deleteClass(id) {
            if (!confirm('Delete this class? Teacher assignments for it are removed.')) return;
            const res = await apiFetch(`/api/school-classes/${id}`, { method: 'DELETE' });
            if (!res.ok) { alert(res.data.message || 'Could not delete class.'); return; }
            document.getElementById('classRosterCard').style.display = 'none';
            await loadClasses();
        }

        function filterAttendanceClass(className) {
            if (JSON.parse(localStorage.getItem('admin_user') || '{}').role !== 'teacher') return;
            switchTab('attendance');
            const select = document.getElementById('attClassSelect');
            if (select) {
                const classOption = Array.from(select.options).find(option => option.value === className);
                if (classOption) select.value = className;
                loadAttendanceRoster();
            }
        }

        async function addClassSubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/school-classes', { method: 'POST', body: JSON.stringify({
                school_id: document.getElementById('classSchoolId').value,
                academic_year_id: document.getElementById('classAcademicYearId').value || null,
                grade: document.getElementById('classGrade').value.trim(),
                class_name: document.getElementById('className').value.trim(),
                capacity: Number(document.getElementById('classCapacity').value)
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not create class.'); return; }
            event.target.reset(); closeModal('classModal'); await loadClasses(); alert('Class created successfully.');
        }

        async function setAcademicYearCurrent(id) {
            const res = await apiFetch(`/api/academic-years/${id}/set-current`, { method: 'POST' });
            if (!res.ok) { alert(res.data.message || 'Could not update academic year.'); return; }
            await loadAcademicYears();
        }

        async function linkGuardianSubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/students/link-guardian', { method: 'POST', body: JSON.stringify({
                student_id: document.getElementById('linkStudentId').value,
                guardian_id: document.getElementById('linkGuardianId').value
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not link guardian.'); return; }
            closeModal('linkGuardianModal'); await loadStudents(); alert(res.data.message || 'Guardian linked.');
        }

        async function loadAcademicYears() {
            const res = await apiFetch('/api/academic-years');
            if (!res.ok) return;
            academicYearsList = res.data.academic_years || [];
            const select = document.getElementById('classAcademicYearId');
            if (select) select.innerHTML = '<option value="">Current / Unassigned</option>' + academicYearsList.map(y => `<option value="${y.id}">${y.name}${y.is_current ? ' (Current)' : ''}</option>`).join('');
            const body = document.getElementById('academicYearsTableBody');
            if (body) body.innerHTML = academicYearsList.length ? academicYearsList.map(y => `<tr><td><strong>${y.name}</strong></td><td>Academic Year</td><td>${y.start_date ? String(y.start_date).slice(0,10) : '—'}</td><td>${y.end_date ? String(y.end_date).slice(0,10) : '—'}</td><td><span class="role-badge ${y.is_current ? 'teacher' : 'guardian'}">${y.is_current ? 'Current' : 'Inactive'}</span></td><td>${y.is_current ? '<span class="btn-sm" aria-label="Current academic year">Current</span>' : `<button class="btn-sm" onclick="setAcademicYearCurrent(${y.id})">Set Current</button>`}</td></tr>`).join('') : '<tr><td colspan="6" style="text-align:center;padding:20px;">No academic years configured</td></tr>';
        }

        async function loadAnnouncements() {
            const res = await apiFetch('/api/announcements');
            if (res.ok && res.data.announcements) {
                announcementsList = res.data.announcements;
                renderAnnouncementsList();
            }
        }

        async function loadPlatformDirectory() {
            const res = await apiFetch('/api/platform/directory');
            if (res.ok && res.data.directory) {
                directoryList = res.data.directory;
                renderPlatformDirectoryTable();
            }
        }

        function renderUsersTable() {
            const tbody = document.getElementById('usersTableBody');
            if (!tbody) return;
            const searchInput = document.getElementById('userSearchInput');
            const search = searchInput ? searchInput.value.toLowerCase() : '';

            let filtered = usersList;
            if (activeRoleFilter !== 'all') {
                filtered = filtered.filter(u => u.role === activeRoleFilter);
            }
            if (search) {
                filtered = filtered.filter(u =>
                    (u.name && u.name.toLowerCase().includes(search)) ||
                    (u.email && u.email.toLowerCase().includes(search)) ||
                    (u.phone_number && u.phone_number.includes(search))
                );
            }

            if (filtered.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">No matching users found</td></tr>';
            } else {
                tbody.innerHTML = filtered.map(u => {
                    const hasEmail = Boolean(u.email && u.email.trim() !== '');
                    const safeEmail = JSON.stringify(u.email || '');
                    const emailBtn = hasEmail ?
                        `<button class="btn-sm" style="background:#2563EB; color:white; border:none; margin-right:4px;" onclick='sendUserPasswordLink(${u.id}, ${safeEmail})' title="Send password creation link for mobile app access">Send Setup Link</button>` :
                        `<button class="btn-sm" style="opacity:0.4; margin-right:4px;" disabled title="No email address">No Email</button>`;
                    return `
                        <tr>
                            <td>#${u.id}</td>
                            <td><strong>${u.name || 'Unnamed'}</strong></td>
                            <td>${hasEmail ? u.email : '<span style="color:#94a3b8; font-style:italic;">None</span>'}</td>
                            <td>${u.phone_number || 'N/A'}</td>
                            <td><span class="role-badge ${u.role}">${u.role}</span></td>
                            <td>
                                ${emailBtn}
                                <button class="btn-sm btn-danger" onclick="deleteUser(${u.id})">Delete</button>
                            </td>
                        </tr>
                    `;
                }).join('');
            }
        }

        function filterUserRole(role, btn) {
            activeRoleFilter = role;
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderUsersTable();
        }

        function renderTeachersTable() {
            const tbody = document.getElementById('teachersTableBody');
            if (!tbody) return;
            if (teachersList.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">No teachers registered yet</td></tr>';
                return;
            }
            tbody.innerHTML = teachersList.map(t => {
                const name = t.user ? t.user.name : (t.name || 'Teacher');
                const email = t.user ? t.user.email : (t.email || 'N/A');
                const phone = t.user ? t.user.phone_number : (t.phone || 'N/A');
                const subjects = Array.isArray(t.subject_specialties) ? t.subject_specialties.join(', ') : (t.subject || 'General');
                const assignedClasses = Array.isArray(t.assigned_classes) ? t.assigned_classes.map(c => `${c.grade} - ${c.class_name}`).join(', ') : (t.assignedClasses || []).map(c => c.class_name).join(', ');
                return `
                    <tr>
                        <td><strong>${name}</strong></td>
                        <td>${subjects}</td>
                        <td>${assignedClasses || 'Unassigned'}</td>
                        <td>${email}</td>
                        <td>${phone}</td>
                        <td>
                            <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">
                                <select id="assignTeacherClass${t.id}" class="form-control" aria-label="Assign teacher class" style="max-width:220px;">
                                    <option value="">Select a class</option>
                                    ${classesList.filter(c => Number(c.school_id) === Number(t.school_id) && !(t.assigned_classes || []).some(a => a.id === c.id)).map(c => `<option value="${c.id}">${escapeTableText(c.grade)} - ${escapeTableText(c.class_name)}</option>`).join('')}
                                </select>
                                <button class="btn-sm" onclick="assignTeacherClass(${t.id})">Assign Class</button>
                                <button class="btn-sm" onclick="sendTeacherSetupLink(${t.id})">Send Setup Link</button>
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');
        }

        async function assignTeacherClass(teacherId) {
            const teacher = teachersList.find(t => t.id === teacherId);
            const classId = Number(document.getElementById(`assignTeacherClass${teacherId}`)?.value);
            if (!teacher || !classId) { alert('Select a class to assign.'); return; }
            const assignments = (teacher.assigned_classes || []).map(c => ({school_class_id: c.id, subject_name: c.pivot?.subject_name || 'Homeroom'}));
            if (!assignments.some(a => a.school_class_id === classId)) assignments.push({school_class_id: classId, subject_name: 'Homeroom'});
            const res = await apiFetch(`/api/teachers/${teacherId}`, {method: 'PUT', body: JSON.stringify({class_assignments: assignments})});
            if (!res.ok) { alert(res.data.message || 'Could not assign this class.'); return; }
            await loadTeachers();
            alert('Class assigned successfully.');
        }

        function renderStudentsTable() {
            const tbody = document.getElementById('studentsTableBody');
            if (!tbody) return;
            const currentRole = JSON.parse(localStorage.getItem('admin_user') || '{}').role;
            if (studentsList.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding: 24px; color: var(--text-secondary);">No enrolled students found</td></tr>';
                return;
            }
            tbody.innerHTML = studentsList.map((s, idx) => {
                const reg = s.reg || `STU-${String(s.id || idx + 1).padStart(3, '0')}`;
                const guardianName = (s.guardians && s.guardians.length > 0) ? s.guardians.map(g => g.name).join(', ') : 'Not linked';
                return `
                    <tr>
                        <td><code>${reg}</code></td>
                        <td><strong>${s.name}</strong></td>
                        <td>${s.class_name || 'Class A'}</td>
                        <td>${guardianName}</td>
                        <td><span class="role-badge primary">${s.grade || 'Primary'}</span></td>
                        <td><strong style="color:var(--text-secondary);">—</strong></td>
                        <td>${currentRole === 'admin' ? `<button class="btn-sm" onclick="openEditStudent(${s.id})">Edit</button> <button class="btn-sm" onclick="openModal('linkGuardianModal')">Link Guardian</button>` : 'Assigned class roster'}</td>
                    </tr>
                `;
            }).join('');
        }

        function renderAnnouncementsList() {
            const container = document.getElementById('announcementsListContainer');
            if (!container) return;
            if (announcementsList.length === 0) {
                container.innerHTML = '<p style="color:var(--text-secondary); text-align:center; padding:20px;">No announcements posted yet.</p>';
                return;
            }
            container.innerHTML = announcementsList.map(a => `
                <div style="padding:16px; border-bottom:1px solid var(--border-color);">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
                        <h4 style="color:var(--primary-blue); font-size:15px; margin:0;">${a.title}</h4>
                        <span style="font-size:11px; color:var(--text-secondary);">${new Date(a.created_at || Date.now()).toLocaleDateString()}</span>
                    </div>
                    <p style="font-size:13px; color:var(--text-primary); margin:0;">${a.content}</p>
                </div>
            `).join('');
        }

        function renderPlatformDirectoryTable() {
            const tbody = document.getElementById('subscriptionControlBody');
            if (!tbody) return;
            const selectedSchoolId = document.getElementById('platformSchoolFilter')?.value || 'all';
            const visibleDirectory = selectedSchoolId === 'all' ? directoryList : directoryList.filter(student => String(student.school_id) === String(selectedSchoolId));
            const activeCount = directoryList.filter(student => student.subscription_status === 'active').length;
            const suspendedCount = directoryList.length - activeCount;
            const actEl = document.getElementById('platformActiveSubs');
            if (actEl) actEl.innerText = activeCount.toString();
            const suspEl = document.getElementById('platformSuspendedSubs');
            if (suspEl) suspEl.innerText = suspendedCount.toString();
            renderPlatformSchoolTabs(selectedSchoolId);
            if (visibleDirectory.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">No enrolled students found for subscription control</td></tr>';
                return;
            }

            tbody.innerHTML = visibleDirectory.map(d => {
                const isActive = d.subscription_status === 'active';

                return `
                    <tr>
                        <td><strong>${escapeTableText(d.student_name)}</strong></td>
                        <td>${escapeTableText(d.school_name || 'School')} (${escapeTableText(d.grade)} ${escapeTableText(d.class_name || '')})</td>
                        <td>${escapeTableText(d.guardian_name || 'Guardian')} (${escapeTableText(d.guardian_phone || 'N/A')})</td>
                        <td>
                            <span class="badge" style="color:${isActive ? '#15803D' : '#B91C1C'}; font-weight:600;">
                                ${isActive ? 'ACTIVE' : 'SUSPENDED'}
                            </span>
                        </td>
                        <td><label style="font-size:11px;">From <input type="date" id="subscriptionStart${d.student_id}" value="${d.subscription_start || new Date().toISOString().slice(0,10)}" class="form-control" style="width:145px;padding:5px;margin:2px 0;"></label><label style="font-size:11px;">Until <input type="date" id="subscriptionEnd${d.student_id}" value="${d.subscription_end || ''}" class="form-control" style="width:145px;padding:5px;margin:2px 0;"></label></td>
                        <td>
                            <button class="btn-sm ${isActive ? 'btn-danger' : ''}" onclick="toggleChildSubscription(${d.student_id}, '${isActive ? 'inactive' : 'active'}')">
                                ${isActive ? 'Suspend Access' : 'Activate Access'}
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');

        }

        // One tab per onboarded school, plus "All schools".
        function renderPlatformSchoolTabs(selectedSchoolId) {
            const tabs = document.getElementById('platformSchoolTabs');
            if (!tabs) return;
            const entries = [{ id: 'all', name: 'All schools' }, ...schoolsList.map(s => ({ id: String(s.id), name: s.name }))];
            tabs.innerHTML = entries.map(entry => {
                const count = entry.id === 'all' ? directoryList.length : directoryList.filter(d => String(d.school_id) === entry.id).length;
                const active = String(selectedSchoolId) === entry.id;
                return `<button type="button" role="tab" aria-selected="${active}" class="btn-sm" onclick="filterPlatformStudents('${entry.id}', false)" style="font-weight:600; ${active ? 'background:var(--primary-blue); color:#fff; border-color:var(--primary-blue);' : ''}">${escapeTableText(entry.name)} (${count})</button>`;
            }).join('');
        }

        function filterPlatformStudents(schoolId, scroll = true) {
            const select = document.getElementById('platformSchoolFilter');
            if (select) select.value = String(schoolId);
            renderPlatformDirectoryTable();
            if (scroll) document.getElementById('platformSchoolTabs')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        function openModal(id) {
            const el = document.getElementById(id);
            if (el) el.classList.add('open');
            if (id === 'teacherAccountModal') loadClasses();
        }

        function closeModal(id) {
            const el = document.getElementById(id);
            if (el) el.classList.remove('open');
        }

        async function createTeacherAccount(e) {
            e.preventDefault();
            const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
            const classId = document.getElementById('newUserClass').value;
            if (!classId) { alert('Select a class for this teacher.'); return; }
            const name = document.getElementById('newUserName').value.trim();
            const email = document.getElementById('newUserEmail').value.trim();
            const phone = document.getElementById('newUserPhone').value.trim();
            const role = document.getElementById('newUserRole').value;
            const password = document.getElementById('newUserPassword') ? document.getElementById('newUserPassword').value.trim() : '';
            const sendInvite = true;

            const payload = {
                name,
                email,
                phone_number: phone,
                class_id: Number(classId),
                role,
                send_invite: sendInvite
            };
            if (currentUser.role === 'admin' && role === 'teacher') payload.school_id = currentUser.school_id;
            if (password) {
                payload.password = password;
            }

            const res = await apiFetch('/api/users', {
                method: 'POST',
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                closeModal('teacherAccountModal');
                document.getElementById('newUserName').value = '';
                document.getElementById('newUserEmail').value = '';
                document.getElementById('newUserPhone').value = '';
                document.getElementById('newUserClass').value = '';
                if (document.getElementById('newUserPassword')) document.getElementById('newUserPassword').value = '';
                await loadTeachers();

                let successMsg = `New ${role.toUpperCase()} "${name}" successfully created!`;
                if (res.data.email_sent) {
                    successMsg += `\n\nA password setup link has been emailed to ${email} for mobile app access.`;
                } else if (email && sendInvite) {
                    successMsg += `\n\nEmail dispatch status: ${res.data.message}`;
                }
                alert(successMsg);
            } else {
                alert(res.data.message || 'Failed to create user in database.');
            }
        }


        // ==========================================
        // EMAIL & SMTP / SES MANAGEMENT FUNCTIONS
        // ==========================================
        async function openMailSettingsModal() {
            openModal('mailSettingsModal');
            const res = await apiFetch('/api/settings/mail');
            if (res.ok && res.data.settings) {
                const s = res.data.settings;
                document.getElementById('cfgMailProvider').value = s.mail_provider || 'gmail';
                document.getElementById('cfgMailHost').value = s.mail_host || 'smtp.gmail.com';
                document.getElementById('cfgMailPort').value = s.mail_port || 587;
                document.getElementById('cfgMailEncryption').value = s.mail_encryption || 'tls';
                document.getElementById('cfgMailFromAddress').value = s.mail_from_address || '';
                document.getElementById('cfgMailFromName').value = s.mail_from_name || 'Edu+Connect Guardianship';
                document.getElementById('cfgMailUsername').value = s.mail_username || '';
                document.getElementById('cfgMailPassword').value = s.mail_password || '';
                if (document.getElementById('cfgSesRegion')) document.getElementById('cfgSesRegion').value = s.mail_ses_region || 'us-east-1';
                if (document.getElementById('cfgPortalUrl')) document.getElementById('cfgPortalUrl').value = s.portal_access_url || '';
                if (document.getElementById('testEmailRecipientInput') && !document.getElementById('testEmailRecipientInput').value) {
                    document.getElementById('testEmailRecipientInput').value = s.mail_from_address || '';
                }
                updateMailPresetUi(s.mail_provider || 'gmail');
            } else {
                updateMailPresetUi('gmail');
            }
        }

        function updateMailPresetUi(provider) {
            document.querySelectorAll('#presetBtnGmail, #presetBtnSes, #presetBtnCustom').forEach(b => b.classList.remove('active'));
            const noticeEl = document.getElementById('mailPresetNotice');
            const sesGroup = document.getElementById('cfgSesRegionGroup');

            if (provider === 'gmail') {
                document.getElementById('presetBtnGmail')?.classList.add('active');
                if (sesGroup) sesGroup.style.display = 'none';
                if (noticeEl) {
                    noticeEl.innerHTML = `<strong>Google / Gmail SMTP:</strong> Use your verified sender address, SMTP username, and a Google app password. Save the settings before sending invitations.`;
                }
            } else if (provider === 'ses') {
                document.getElementById('presetBtnSes')?.classList.add('active');
                if (sesGroup) sesGroup.style.display = 'block';
                if (noticeEl) {
                    noticeEl.innerHTML = `<strong>Amazon SES:</strong> Configure region-specific SMTP credentials and a verified sender identity before sending invitations.`;
                }
            } else {
                document.getElementById('presetBtnCustom')?.classList.add('active');
                if (sesGroup) sesGroup.style.display = 'none';
                if (noticeEl) {
                    noticeEl.innerHTML = `<strong>Custom SMTP Active:</strong> Standard SMTP delivery using your custom host, port, authentication credentials and encryption parameters.`;
                }
            }
        }

        function applyMailPreset(provider) {
            document.getElementById('cfgMailProvider').value = provider;
            updateMailPresetUi(provider);

            if (provider === 'gmail') {
                document.getElementById('cfgMailHost').value = 'smtp.gmail.com';
                document.getElementById('cfgMailPort').value = '587';
                document.getElementById('cfgMailEncryption').value = 'tls';
                if (!document.getElementById('cfgMailFromAddress').value) {
                    document.getElementById('cfgMailFromAddress').value = '';
                }
                if (!document.getElementById('cfgMailUsername').value) {
                    document.getElementById('cfgMailUsername').value = '';
                }
            } else if (provider === 'ses') {
                const region = document.getElementById('cfgSesRegion')?.value || 'us-east-1';
                document.getElementById('cfgMailHost').value = `email-smtp.${region}.amazonaws.com`;
                document.getElementById('cfgMailPort').value = '587';
                document.getElementById('cfgMailEncryption').value = 'tls';
                if (!document.getElementById('cfgMailFromAddress').value) {
                    document.getElementById('cfgMailFromAddress').value = '';
                }
            }
        }

        function handleSesRegionChange(region) {
            if (document.getElementById('cfgMailProvider').value === 'ses') {
                document.getElementById('cfgMailHost').value = `email-smtp.${region}.amazonaws.com`;
            }
        }

        async function saveMailSettingsSubmit(e) {
            e.preventDefault();
            const payload = {
                mail_provider: document.getElementById('cfgMailProvider').value,
                mail_host: document.getElementById('cfgMailHost').value.trim(),
                mail_port: parseInt(document.getElementById('cfgMailPort').value) || 587,
                mail_encryption: document.getElementById('cfgMailEncryption').value,
                mail_from_address: document.getElementById('cfgMailFromAddress').value.trim(),
                mail_from_name: document.getElementById('cfgMailFromName').value.trim(),
                mail_username: document.getElementById('cfgMailUsername').value.trim(),
                mail_password: document.getElementById('cfgMailPassword').value.trim(),
                mail_ses_region: document.getElementById('cfgSesRegion')?.value || 'us-east-1',
                portal_access_url: document.getElementById('cfgPortalUrl')?.value.trim() || null
            };

            const res = await apiFetch('/api/settings/mail', {
                method: 'POST',
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                alert('Email gateway settings saved successfully!');
            } else {
                alert(res.data.message || 'Failed to save email settings.');
            }
        }

        async function sendTestEmailSubmit() {
            const btn = document.getElementById('btnSendTestEmail');
            const resultBox = document.getElementById('testEmailResult');
            const recipient = document.getElementById('testEmailRecipientInput').value.trim();

            if (!recipient) {
                alert('Please provide a recipient email address.');
                return;
            }

            btn.disabled = true;
            btn.innerText = 'Connecting & Sending...';
            resultBox.style.display = 'block';
            resultBox.style.background = '#F8FAFC';
            resultBox.style.color = '#475569';
            resultBox.style.border = '1px solid #CBD5E1';
            resultBox.innerHTML = '<em>Connecting to mail host and attempting delivery...</em>';

            const res = await apiFetch('/api/settings/mail/test', {
                method: 'POST',
                body: JSON.stringify({ recipient })
            });

            btn.disabled = false;
            btn.innerText = 'Send Test Email';

            if (res.ok) {
                resultBox.style.background = '#DCFCE7';
                resultBox.style.color = '#15803D';
                resultBox.style.border = '1px solid #86EFAC';
                resultBox.innerHTML = `<strong>Verification Success:</strong> ${res.data.message || 'Test email dispatched and accepted!'}`;
            } else {
                resultBox.style.background = '#FEE2E2';
                resultBox.style.color = '#B91C1C';
                resultBox.style.border = '1px solid #FCA5A5';
                resultBox.innerHTML = `<strong>Delivery Failed:</strong> ${res.data.message || 'Failed to dispatch email.'}`;
            }
        }

        async function sendTeacherSetupLink(teacherId) {
            const teacher = teachersList.find(t => t.id === teacherId);
            if (!teacher?.user?.email) { alert('This teacher has no email address.'); return; }
            await sendUserPasswordLink(teacher.user.id, teacher.user.email);
        }

        async function sendUserPasswordLink(userId, userEmail) {
            if (!confirm(`Send mobile app password creation link to "${userEmail}"?`)) {
                return;
            }

            const res = await apiFetch(`/api/users/${userId}/send-link`, {
                method: 'POST',
                body: JSON.stringify({})
            });

            if (res.ok) {
                alert(`Password link dispatched successfully to ${userEmail}!\n\nThe user can now open the link in their email to create their password and sign in to the mobile application.`);
            } else {
                alert(res.data.message || 'Failed to dispatch password setup email. Please verify SMTP gateway settings.');
            }
        }

        async function deleteUser(id) {
            if (confirm('Are you sure you want to delete user #' + id + '?')) {
                const res = await apiFetch(`/api/users/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    await loadUsers();
                    alert('User #' + id + ' deleted from database.');
                } else {
                    alert(res.data.message || 'Could not delete user.');
                }
            }
        }

        async function addTeacherSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('tName').value.trim();
            const subject = document.getElementById('tSubject').value.trim();
            const className = document.getElementById('tClass').value.trim();
            const email = document.getElementById('tEmail').value.trim();
            const phone = document.getElementById('tPhone').value.trim();
            const schoolId = document.getElementById('tSchoolId').value;
            if (!schoolId) { alert('Create a school before adding a teacher.'); return; }
            const selectedClass = classesList.find(item => String(item.class_name) === className && String(item.school_id) === String(schoolId));
            if (!selectedClass) { alert('Select a class at the teacher\'s school.'); return; }

            const res = await apiFetch('/api/teachers', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    email,
                    phone,
                    school_id: Number(schoolId),
                    subject_specialties: [subject],
                    class_name: className
                })
            });

            if (res.ok) {
                closeModal('teacherModal');
                await loadTeachers();
                alert('Teacher "' + name + '" saved to database!');
            } else {
                alert(res.data.message || 'Failed to save teacher.');
            }
        }

        async function addStudentSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('sName').value.trim();
            const classId = document.getElementById('sClass').value;
            const guardian = document.getElementById('sGuardian').value.trim();
            const selectedClass = classesList.find(item => String(item.id) === String(classId));
            if (!selectedClass) { alert('Select a class for this student.'); return; }

            const res = await apiFetch('/api/students', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    class_id: Number(classId),
                    dob: document.getElementById('sDob')?.value || null,
                    guardian_name: guardian || null,
                    guardian_email: document.getElementById('sGuardianEmail')?.value.trim() || null,
                    guardian_phone: document.getElementById('sGuardianPhone')?.value.trim() || null
                })
            });

            if (res.ok) {
                closeModal('studentModal');
                await loadStudents();
                const currentRole = JSON.parse(localStorage.getItem('admin_user') || '{}').role;
                if (currentRole === 'admin') {
                    await loadUsers();
                    recalculateStatistics();
                }
                alert('Student "' + name + '" enrolled in database!');
            } else {
                alert(res.data.message || 'Failed to enroll student.');
            }
        }

        function openEditStudent(studentId) {
            const student = studentsList.find(item => Number(item.id) === Number(studentId));
            if (!student) return alert('Student record is no longer available.');
            document.getElementById('editStudentId').value = student.id;
            document.getElementById('editStudentName').value = student.name || '';
            document.getElementById('editStudentDob').value = student.dob ? String(student.dob).slice(0, 10) : '';
            const select = document.getElementById('editStudentClass');
            select.innerHTML = '<option value="">Select class</option>' + classesList.map(item => `<option value="${item.id}" ${item.class_name === student.class_name && item.grade === student.grade ? 'selected' : ''}>${escapeTableText(item.class_name)} (${escapeTableText(item.grade)})</option>`).join('');
            openModal('editStudentModal');
        }

        async function editStudentSubmit(event) {
            event.preventDefault();
            const studentId = document.getElementById('editStudentId').value;
            const res = await apiFetch(`/api/students/${studentId}`, { method: 'PUT', body: JSON.stringify({
                name: document.getElementById('editStudentName').value.trim(),
                class_id: Number(document.getElementById('editStudentClass').value),
                dob: document.getElementById('editStudentDob').value || null
            }) });
            if (!res.ok) return alert(res.data?.message || 'Could not update student record.');
            closeModal('editStudentModal');
            await loadStudents();
            alert(res.data.message || 'Student record updated.');
        }

        async function onboardSchoolSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('obsName').value.trim();
            const type = document.getElementById('obsType').value;
            const adminName = document.getElementById('obsAdminName').value.trim();
            const adminEmail = document.getElementById('obsAdminEmail').value.trim();
            const adminPhone = document.getElementById('obsAdminPhone').value.trim();
            const color = document.getElementById('obsColor').value;

            const res = await apiFetch('/api/platform/schools', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    type,
                    primary_admin_name: adminName,
                    primary_admin_email: adminEmail,
                    primary_admin_phone: adminPhone,
                    branding_color: color
                })
            });

            if (res.ok) {
                closeModal('onboardSchoolModal');
                await Promise.all([loadSchools(), loadPlatformDirectory()]);
                alert(`School "${name}" onboarded successfully.${res.data.admin_invitation_message ? ` ${res.data.admin_invitation_message}` : ''}`);
            } else {
                alert(res.data.message || 'Failed to onboard school.');
            }
        }

        async function toggleChildSubscription(studentId, targetStatus) {
            const actionLabel = targetStatus === 'inactive' ? 'SUSPEND' : 'ACTIVATE';
            if (confirm(`Are you sure you want to ${actionLabel} subscription access for student #${studentId}?`)) {
                const today = new Date().toISOString().slice(0, 10);
                let startDate = document.getElementById(`subscriptionStart${studentId}`)?.value || today;
                let endDate = document.getElementById(`subscriptionEnd${studentId}`)?.value || null;
                if (startDate < today) startDate = today;
                if (endDate && endDate < today) endDate = null;
                const res = await apiFetch('/api/platform/subscriptions/toggle', {
                    method: 'POST',
                    body: JSON.stringify({
                        student_id: studentId,
                        status: targetStatus,
                        start_date: startDate,
                        end_date: endDate
                    })
                });
                if (res.ok) {
                    await loadPlatformDirectory();
                    alert(`Subscription successfully updated to ${targetStatus.toUpperCase()}.`);
                } else {
                    alert(res.data.message || 'Failed to toggle subscription.');
                }
            }
        }

        // ================= ATTENDANCE REGISTER =================
        async function loadAttendanceRoster() {
            const dateInput = document.getElementById('attDate');
            if (dateInput && !dateInput.value) {
                dateInput.value = new Date().toISOString().split('T')[0];
            }
            const date = dateInput ? dateInput.value : '';
            const classSelect = document.getElementById('attClassSelect');
            const className = classSelect ? classSelect.value : 'all';

            const tbody = document.getElementById('attendanceRosterBody');
            if (tbody) {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-secondary);">Loading student register...</td></tr>';
            }

            const res = await apiFetch(`/api/attendance/roster?date=${encodeURIComponent(date)}&class_name=${encodeURIComponent(className)}`);
            if (res.ok && res.data.roster) {
                attendanceRosterList = res.data.roster;
                if (!tbody) return;

                if (attendanceRosterList.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; padding:24px; color:var(--text-secondary);">No students enrolled for selected class/filter</td></tr>';
                    return;
                }

                tbody.innerHTML = attendanceRosterList.map(r => `
                    <tr>
                        <td><code>${r.reg || ('STU-00' + r.student_id)}</code></td>
                        <td>
                            <strong>${r.name}</strong>
                            <span class="badge" style="color:#475569; margin-left:6px; font-size:11px;">${r.class_name || r.grade}</span>
                        </td>
                        <td>
                            <div style="display:flex; gap:16px; align-items:center;">
                                <label style="cursor:pointer; display:flex; align-items:center; gap:4px; color:#15803D; font-weight:600; font-size:13px;">
                                    <input type="radio" name="att_status_${r.student_id}" value="present" ${r.status === 'present' ? 'checked' : ''}> Present
                                </label>
                                <label style="cursor:pointer; display:flex; align-items:center; gap:4px; color:#D97706; font-weight:600; font-size:13px;">
                                    <input type="radio" name="att_status_${r.student_id}" value="late" ${r.status === 'late' ? 'checked' : ''}> Late
                                </label>
                                <label style="cursor:pointer; display:flex; align-items:center; gap:4px; color:#DC2626; font-weight:600; font-size:13px;">
                                    <input type="radio" name="att_status_${r.student_id}" value="absent" ${r.status === 'absent' ? 'checked' : ''}> Absent
                                </label>
                            </div>
                        </td>
                        <td>
                            <input type="text" id="att_remarks_${r.student_id}" class="form-control" style="font-size:12px; height:34px;" value="${r.remarks || ''}" placeholder="Subject / remark (optional)">
                        </td>
                    </tr>
                `).join('');
            }
        }

        async function saveAttendanceRegister() {
            const dateInput = document.getElementById('attDate');
            const date = dateInput && dateInput.value ? dateInput.value : new Date().toISOString().split('T')[0];

            if (!attendanceRosterList || attendanceRosterList.length === 0) {
                alert('No students currently in the register to mark.');
                return;
            }

            const records = attendanceRosterList.map(r => {
                const radio = document.querySelector(`input[name="att_status_${r.student_id}"]:checked`);
                const status = radio ? radio.value : 'present';
                const remarksInput = document.getElementById(`att_remarks_${r.student_id}`);
                const remarks = remarksInput ? remarksInput.value.trim() : '';
                return {
                    student_id: r.student_id,
                    status: status,
                    remarks: remarks
                };
            });

            const res = await apiFetch('/api/attendance/mark', {
                method: 'POST',
                body: JSON.stringify({ date, records })
            });

            if (res.ok) {
                alert(`Attendance register for ${date} successfully recorded in database!`);
                await loadAttendanceRoster();
                await loadAdminStats();
            } else {
                alert(res.data.message || 'Failed to save attendance register.');
            }
        }

        // ================= LEARNING JOURNAL =================
        function toggleJournalTypeFields() {
            const type = document.getElementById('journalType').value;
            const mediaGrp = document.getElementById('journalMediaGroup');
            if (mediaGrp) mediaGrp.style.display = 'block';
        }

        async function loadJournalFeed() {
            const container = document.getElementById('journalFeedContainer');
            if (!container) return;

            const res = await apiFetch('/api/journal');
            if (res.ok && res.data.entries) {
                journalFeedList = res.data.entries;
                if (journalFeedList.length === 0) {
                    container.innerHTML = '<p style="color:var(--text-secondary); text-align:center; padding:24px;">No learning journal entries posted yet. Use the form on the left to post work samples.</p>';
                    return;
                }

                const badgeColors = {
                    photo: { bg: '#DBEAFE', color: '#1E40AF' },
                    drawing: { bg: '#FEF3C7', color: '#B45309' },
                    voice: { bg: '#F3E8FF', color: '#7E22CE' },
                    text: { bg: '#F1F5F9', color: '#334155' }
                };

                container.innerHTML = journalFeedList.map(item => {
                    const badge = badgeColors[item.type] || { bg: '#F1F5F9', color: '#334155' };
                    let mediaHtml = '';
                    if (item.media_url) {
                        mediaHtml = `
                            <div style="margin-top:10px;">
                                <img src="${item.media_url}" style="max-height:220px; width:100%; object-fit:cover; border-radius:6px; border:1px solid #E2E8F0;" onerror="this.style.display='none'">
                            </div>
                        `;
                    }
                    return `
                        <div class="table-card" style="padding:16px; margin-bottom:14px;">
                            <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:8px;">
                                <div>
                                    <strong style="color:var(--text-primary); font-size:14px;">${item.student_name}</strong>
                                    <span style="font-size:12px; color:var(--text-secondary); margin-left:6px;">(${item.class_name || item.grade || 'Learner'})</span>
                                    <div style="font-size:11px; color:var(--text-secondary); margin-top:2px;">By ${item.author_name} &bull; ${item.created_at}</div>
                                </div>
                                <div style="display:flex; align-items:center; gap:8px;">
                                    <span class="badge" style="color:${badge.color}; font-size:11px; text-transform:uppercase;">${item.type}</span>
                                    <button class="btn-sm btn-danger" style="padding:2px 8px; font-size:11px;" onclick="deleteJournalEntry(${item.id})">Delete</button>
                                </div>
                            </div>
                            ${item.caption ? `<p style="font-size:13px; color:var(--text-primary); margin:6px 0; line-height:1.4;">${item.caption}</p>` : ''}
                            ${mediaHtml}
                        </div>
                    `;
                }).join('');
            }
        }

        async function handleJournalPostSubmit(e) {
            e.preventDefault();
            const studentId = document.getElementById('journalStudentId').value;
            if (!studentId) {
                alert('Please select an enrolled student.');
                return;
            }
            const type = document.getElementById('journalType').value;
            const caption = document.getElementById('journalCaption') ? document.getElementById('journalCaption').value.trim() : '';
            const fileInput = document.getElementById('journalImageFile');
            const mediaUrlInput = document.getElementById('journalMediaUrl');

            const formData = new FormData();
            formData.append('student_id', studentId);
            formData.append('type', type);
            formData.append('caption', caption);

            if (fileInput && fileInput.files[0]) {
                formData.append('image', fileInput.files[0]);
            } else if (mediaUrlInput && mediaUrlInput.value.trim()) {
                formData.append('media_url', mediaUrlInput.value.trim());
            }

            const res = await apiFetch('/api/journal', {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                alert('Learning Journal entry posted successfully!');
                if (document.getElementById('journalCaption')) document.getElementById('journalCaption').value = '';
                if (fileInput) fileInput.value = '';
                if (mediaUrlInput) mediaUrlInput.value = '';
                await loadJournalFeed();
            } else {
                alert(res.data.message || 'Failed to post learning journal entry.');
            }
        }

        async function deleteJournalEntry(id) {
            if (confirm('Are you sure you want to remove this journal entry?')) {
                const res = await apiFetch(`/api/journal/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    await loadJournalFeed();
                } else {
                    alert(res.data.message || 'Could not delete entry.');
                }
            }
        }

        // ================= SHARED SCHOOL DOCUMENTS =================
        async function loadSchoolDocuments() {
            const body = document.getElementById('schoolDocumentsBody');
            body.innerHTML = '<tr><td colspan="4">Loading documents…</td></tr>';
            const res = await apiFetch('/api/documents');
            if (!res.ok) {
                body.innerHTML = '<tr><td colspan="4">Could not load documents. Reopen this section to retry.</td></tr>';
                return;
            }
            const select = document.getElementById('documentClass');
            const previous = select.value;
            select.innerHTML = '<option value="">Whole school</option>' + classesList.map(c => `<option value="${Number(c.id)}">${escapeTableText(c.grade)} - ${escapeTableText(c.class_name)}</option>`).join('');
            select.value = previous;
            body.innerHTML = (res.data.documents || []).map(d => `<tr>
                <td><strong>${escapeTableText(d.title)}</strong><br>${escapeTableText(d.description)}</td>
                <td>${escapeTableText(d.audience)}</td>
                <td>${escapeTableText(d.file_name)}<br><small>${Math.ceil(d.file_size / 1024)} KB</small></td>
                <td><button class="btn-sm" onclick="downloadSchoolDocument(${Number(d.id)})">Download</button>
                <button class="btn-sm btn-danger" onclick="deleteSchoolDocument(${Number(d.id)})">Delete</button></td>
            </tr>`).join('') || '<tr><td colspan="4">No school documents uploaded yet.</td></tr>';
        }

        async function uploadSchoolDocument(event) {
            event.preventDefault();
            const form = event.currentTarget;
            const button = document.getElementById('documentUploadButton');
            const status = document.getElementById('documentUploadStatus');
            const file = document.getElementById('schoolDocumentFile').files[0];
            if (!file || file.size > 10 * 1024 * 1024) {
                status.textContent = 'Choose a document no larger than 10 MB.';
                return;
            }
            button.disabled = true;
            status.textContent = 'Uploading document…';
            const res = await apiFetch('/api/documents', {method: 'POST', body: new FormData(form)});
            button.disabled = false;
            if (!res.ok) {
                status.textContent = Object.values(res.data.errors || {}).flat().join(' ') || res.data.message || 'Upload failed. Please try again.';
                return;
            }
            form.reset();
            status.textContent = 'Document uploaded successfully.';
            await loadSchoolDocuments();
        }

        async function downloadSchoolDocument(id) {
            const res = await apiFetch(`/api/documents/${id}/download`);
            if (!res.ok) { alert(res.data.message || 'Document could not be downloaded.'); return; }
            const link = document.createElement('a');
            link.href = res.data.download_url;
            link.rel = 'noopener';
            link.click();
        }

        async function deleteSchoolDocument(id) {
            if (!confirm('Delete this shared document? It will no longer be available to download.')) return;
            const res = await apiFetch(`/api/documents/${id}`, {method: 'DELETE'});
            if (res.ok) await loadSchoolDocuments();
            else alert(res.data.message || 'Document could not be deleted.');
        }

        // ================= REPORTS & CIRCULARS =================
        async function loadReports() {
            const tbody = document.getElementById('reportsTableBody');
            if (!tbody) return;

            const res = await apiFetch('/api/reports');
            if (res.ok && res.data.reports) {
                reportsList = res.data.reports;
                if (reportsList.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding:24px; color:var(--text-secondary);">No academic reports or circulars uploaded yet</td></tr>';
                    return;
                }

                const typeLabels = {
                    report: 'Academic Term Report Card',
                    merit: 'Merit Commendation',
                    certificate: 'Official Certificate'
                };

                tbody.innerHTML = reportsList.map(r => `
                    <tr>
                        <td><strong>${r.student_name}</strong><br><small style="color:var(--text-secondary);">${r.class_name || r.grade}</small></td>
                        <td><strong>${r.title}</strong></td>
                        <td><span class="badge" style="color:#1D4ED8;">${typeLabels[r.type] || r.type}</span></td>
                        <td>${r.created_at}</td>
                        <td style="white-space:nowrap;">
                            <a href="${r.file_url}" target="_blank" class="btn-sm" style="text-decoration:none; display:inline-block; margin-right:6px;">Download</a>
                            <button class="btn-sm btn-danger" onclick="deleteReport(${r.id})">Delete</button>
                        </td>
                    </tr>
                `).join('');
            }
        }

        async function uploadReportSubmit(e) {
            e.preventDefault();
            const studentId = document.getElementById('repStudentId').value;
            if (!studentId) {
                alert('Please select a student.');
                return;
            }
            const title = document.getElementById('repTitle').value.trim();
            const type = document.getElementById('repType').value;
            const fileInput = document.getElementById('repFile');

            const formData = new FormData();
            formData.append('student_id', studentId);
            formData.append('title', title);
            formData.append('type', type);

            if (fileInput && fileInput.files[0]) {
                formData.append('file', fileInput.files[0]);
            }

            const res = await apiFetch('/api/reports/upload', {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                closeModal('reportModal');
                if (fileInput) fileInput.value = '';
                if (document.getElementById('repTitle')) document.getElementById('repTitle').value = '';
                await loadReports();
                alert('Academic report card uploaded and issued successfully!');
            } else {
                alert(res.data.message || 'Failed to upload report document.');
            }
        }

        async function deleteReport(id) {
            if (confirm('Are you sure you want to delete this report document?')) {
                const res = await apiFetch(`/api/reports/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    await loadReports();
                } else {
                    alert(res.data.message || 'Could not delete report.');
                }
            }
        }

        // ================= UNIFORM CATALOG STOREFRONT =================
        function autoCalcZig() {
            const usd = parseFloat(document.getElementById('uniPriceUsd').value) || 0;
            const zigInput = document.getElementById('uniPriceZig');
            if (zigInput) {
                zigInput.value = (usd * 13.5).toFixed(2);
            }
        }

        async function loadUniforms() {
            const tbody = document.getElementById('uniformsTableBody');
            if (!tbody) return;

            const res = await apiFetch('/api/uniforms');
            if (res.ok && res.data.uniforms) {
                uniformsList = res.data.uniforms;
                if (uniformsList.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:24px; color:var(--text-secondary);">No uniform items in catalog yet. Click "Add Uniform Item" above to add uniforms.</td></tr>';
                    return;
                }

                tbody.innerHTML = uniformsList.map(u => {
                    const safeImg = u.image_url ? u.image_url : '/assets/icons8-wallet.svg';
                    const sizesStr = Array.isArray(u.sizes) ? u.sizes.join(', ') : (u.sizes || 'Standard');
                    const escapedName = (u.name || '').replace(/'/g, "\\'").replace(/"/g, '&quot;');

                    return `
                        <tr>
                            <td>
                                <img src="${safeImg}" alt="${escapedName}" style="width:48px; height:48px; object-fit:cover; border-radius:6px; border:1px solid #E2E8F0;" onerror="this.src='/assets/icons8-wallet.svg'">
                            </td>
                            <td>
                                <strong>${u.name}</strong><br>
                                <small style="color:var(--text-secondary);">Code: ${u.item_code} | Sizes: ${sizesStr}</small>
                            </td>
                            <td><span class="badge" style="color:#4338CA;">${u.category}</span></td>
                            <td>
                                <strong style="color:var(--primary-blue);">$${Number(u.price_usd).toFixed(2)} USD</strong><br>
                                <small style="color:var(--text-secondary);">${Number(u.price_zig).toFixed(2)} ZiG</small>
                            </td>
                            <td>
                                <span class="badge" style="color:${u.stock_count > 0 ? '#15803D' : '#B91C1C'}; font-weight:600;">
                                    ${u.stock_count > 0 ? (u.stock_count + ' in stock') : 'Out of stock'}
                                </span>
                            </td>
                            <td>${u.school_name || 'All Schools'}</td>
                            <td style="white-space:nowrap;">
                                <button class="btn-sm" onclick="openEditUniform(${u.id})">Edit</button>
                                <button class="btn-sm btn-danger" style="margin-left:6px;" onclick="deleteUniform(${u.id})">Delete</button>
                            </td>
                        </tr>
                    `;
                }).join('');
            }
        }

        function autoCalcEditZig() {
            const usd = parseFloat(document.getElementById('editUniPriceUsd').value) || 0;
            const zigInput = document.getElementById('editUniPriceZig');
            if (zigInput) {
                zigInput.value = (usd * 13.5).toFixed(2);
            }
        }

        async function addUniformSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('uniName').value.trim();
            const category = document.getElementById('uniCategory').value;
            const schoolId = document.getElementById('uniSchoolId').value;
            const priceUsd = document.getElementById('uniPriceUsd').value;
            const priceZig = document.getElementById('uniPriceZig').value;
            const sizes = document.getElementById('uniSizes').value.trim();
            const stock = document.getElementById('uniStock').value;
            const description = document.getElementById('uniDescription').value.trim();
            const fileInput = document.getElementById('uniImageFile');
            const urlInput = document.getElementById('uniImageUrl');

            const formData = new FormData();
            formData.append('name', name);
            formData.append('category', category);
            if (schoolId) formData.append('school_id', schoolId);
            formData.append('price_usd', priceUsd);
            if (priceZig) formData.append('price_zig', priceZig);
            formData.append('sizes', sizes);
            formData.append('stock_count', stock);
            formData.append('description', description);

            if (fileInput && fileInput.files[0]) {
                formData.append('image', fileInput.files[0]);
            } else if (urlInput && urlInput.value.trim()) {
                formData.append('image_url', urlInput.value.trim());
            }

            const res = await apiFetch('/api/uniforms', {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                closeModal('uniformModal');
                if (fileInput) fileInput.value = '';
                if (urlInput) urlInput.value = '';
                document.getElementById('uniName').value = '';
                document.getElementById('uniPriceUsd').value = '';
                document.getElementById('uniPriceZig').value = '';
                document.getElementById('uniDescription').value = '';
                await loadUniforms();
                alert(`Uniform item "${name}" successfully saved to catalog!`);
            } else {
                alert(res.data.message || 'Failed to add uniform item.');
            }
        }

        function openEditUniform(id) {
            const u = uniformsList.find(item => item.id == id);
            if (!u) {
                alert('Uniform item not found in catalog.');
                return;
            }
            document.getElementById('editUniId').value = u.id;
            document.getElementById('editUniName').value = u.name || '';
            document.getElementById('editUniCategory').value = u.category || 'Formal Wear';
            document.getElementById('editUniStock').value = u.stock_count ?? 50;
            document.getElementById('editUniPriceUsd').value = u.price_usd || '';
            document.getElementById('editUniPriceZig').value = u.price_zig || (u.price_usd ? (u.price_usd * 13.5).toFixed(2) : '');
            document.getElementById('editUniSizes').value = Array.isArray(u.sizes) ? u.sizes.join(', ') : (u.sizes || '');
            document.getElementById('editUniDescription').value = u.description || '';
            document.getElementById('editUniImageUrl').value = u.image_url || '';

            const fileInput = document.getElementById('editUniImageFile');
            if (fileInput) fileInput.value = '';

            const preview = document.getElementById('editUniImagePreview');
            if (preview) {
                if (u.image_url) {
                    preview.src = u.image_url;
                    preview.style.display = 'block';
                } else {
                    preview.style.display = 'none';
                }
            }
            openModal('editUniformModal');
        }

        async function editUniformSubmit(e) {
            e.preventDefault();
            const id = document.getElementById('editUniId').value;
            const name = document.getElementById('editUniName').value.trim();
            const category = document.getElementById('editUniCategory').value;
            const stock = document.getElementById('editUniStock').value;
            const priceUsd = document.getElementById('editUniPriceUsd').value;
            const priceZig = document.getElementById('editUniPriceZig').value;
            const sizes = document.getElementById('editUniSizes').value.trim();
            const description = document.getElementById('editUniDescription').value.trim();
            const fileInput = document.getElementById('editUniImageFile');
            const urlInput = document.getElementById('editUniImageUrl');

            const formData = new FormData();
            formData.append('_method', 'PUT');
            formData.append('name', name);
            formData.append('category', category);
            formData.append('stock_count', stock);
            formData.append('price_usd', priceUsd);
            if (priceZig) formData.append('price_zig', priceZig);
            formData.append('sizes', sizes);
            formData.append('description', description);

            if (fileInput && fileInput.files[0]) {
                formData.append('image', fileInput.files[0]);
            } else if (urlInput && urlInput.value.trim()) {
                formData.append('image_url', urlInput.value.trim());
            }

            const res = await apiFetch(`/api/uniforms/${id}`, {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                closeModal('editUniformModal');
                if (fileInput) fileInput.value = '';
                await loadUniforms();
                alert(`Uniform item "${name}" updated successfully with new details and image!`);
            } else {
                alert(res.data.message || 'Failed to update uniform.');
            }
        }

        async function deleteUniform(id) {
            const item = uniformsList.find(u => u.id == id);
            const itemName = item ? item.name : `#${id}`;
            if (confirm(`Are you sure you want to permanently delete uniform "${itemName}" from the store catalog?`)) {
                const res = await apiFetch(`/api/uniforms/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    alert(`Uniform "${itemName}" deleted successfully!`);
                    await loadUniforms();
                } else {
                    alert(res.data.message || 'Could not delete uniform.');
                }
            }
        }

        async function handleAnnouncementSubmit(e) {
            e.preventDefault();
            const title = document.getElementById('annTitle').value.trim();
            const content = document.getElementById('annContent').value.trim();
            const audience = document.getElementById('annAudience') ? document.getElementById('annAudience').value : 'all';
            const schoolId = document.getElementById('annSchoolId')?.value || schoolsList[0]?.id;
            if (!schoolId) { alert('Create a school before publishing an announcement.'); return; }

            const res = await apiFetch('/api/announcements', {
                method: 'POST',
                body: JSON.stringify({
                    title,
                    content,
                    school_id: Number(schoolId),
                    audience_role: audience
                })
            });

            if (res.ok) {
                await loadAnnouncements();
                document.getElementById('announcementForm').reset();
                alert('Announcement published successfully!');
            } else {
                alert(res.data.message || 'Failed to publish announcement.');
            }
        }

        function recalculateStatistics() {
            const totalStudents = studentsList.length;
            const kpiEl = document.getElementById('kpiStudents');
            if (kpiEl) kpiEl.innerText = totalStudents.toLocaleString();

        }

        // Draws the dashboard charts from /api/admin/dashboard-stats; nothing here is sample data.
        function initDashboardCharts(charts) {
            if (typeof Chart === 'undefined' || !charts) return;
            const font = { legend: { position: 'top', labels: { font: { family: 'Cabin' } } } };
            const draw = (id, config, hasData, emptyText) => {
                const canvas = document.getElementById(id);
                if (!canvas) return;
                if (canvas._chartInstance) canvas._chartInstance.destroy();
                canvas._chartInstance = null;
                let note = canvas.parentElement.querySelector('.chart-empty');
                if (!hasData) {
                    canvas.style.display = 'none';
                    if (!note) {
                        note = document.createElement('p');
                        note.className = 'chart-empty';
                        note.style.cssText = 'color:var(--text-secondary);font-size:13px;text-align:center;padding-top:80px;margin:0;';
                        canvas.parentElement.appendChild(note);
                    }
                    note.textContent = emptyText;
                    return;
                }
                if (note) note.remove();
                canvas.style.display = '';
                canvas._chartInstance = new Chart(canvas, config);
            };

            const weekly = charts.attendance_weekly || [];
            draw('revenueChart', {
                type: 'line',
                data: { labels: charts.weeks, datasets: [{ label: 'Attendance (%)', data: weekly, borderColor: '#3B5998', backgroundColor: 'rgba(59, 89, 152, 0.12)', fill: true, tension: 0.3, borderWidth: 2.5, spanGaps: true }] },
                options: { responsive: true, maintainAspectRatio: false, plugins: font, scales: { y: { min: 0, max: 100, grid: { color: '#F1F5F9' } }, x: { grid: { display: false } } } }
            }, weekly.some(v => v !== null), 'No attendance registers saved in the last six weeks.');

            const byClass = charts.attendance_by_class || { labels: [], rates: [] };
            draw('attendanceChart', {
                type: 'bar',
                data: { labels: byClass.labels, datasets: [{ label: 'Attendance (%)', data: byClass.rates, backgroundColor: '#3B5998' }] },
                options: { responsive: true, maintainAspectRatio: false, plugins: font, scales: { y: { min: 0, max: 100, grid: { color: '#F1F5F9' } }, x: { grid: { display: false } } } }
            }, byClass.labels.length > 0, 'No attendance registers saved in the last 30 days.');

            const a = charts.activity_weekly || {};
            const series = [['Journal posts', a.journal, '#0EA5E9'], ['Homework', a.homework, '#22C55E'], ['Behaviour records', a.behaviour, '#F59E0B'], ['Attendance marks', a.attendance_marks, '#1E3A8A']];
            draw('activityChart', {
                type: 'line',
                data: { labels: charts.weeks, datasets: series.map(([label, data, color]) => ({ label, data: data || [], borderColor: color, backgroundColor: color, fill: false, tension: 0.3 })) },
                options: { responsive: true, maintainAspectRatio: false, plugins: font, scales: { y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#F1F5F9' } }, x: { grid: { display: false } } } }
            }, series.some(([, data]) => (data || []).some(v => v > 0)), 'No teacher activity recorded in the last six weeks.');
        }

        window.addEventListener('DOMContentLoaded', async () => {
            // Check auth session
            const token = localStorage.getItem('admin_token');
            const savedUser = localStorage.getItem('admin_user');
            if (token && savedUser) {
                try {
                    const u = JSON.parse(savedUser);
                    document.getElementById('headerAdminName').innerText = u.name || 'Administrator';
                    document.getElementById('headerAdminRole').innerText = u.role === 'website_admin' ? 'Platform Owner' : 'School Admin';
                    document.getElementById('headerAvatar').innerText = (u.name || 'Admin').split(' ').map(n=>n[0]).join('').substring(0, 2).toUpperCase();
                    document.getElementById('authScreen').classList.add('hidden');
                    loadAllDashboardData();
                } catch (_) {
                    document.getElementById('authScreen').classList.remove('hidden');
                }
            } else {
                document.getElementById('authScreen').classList.remove('hidden');
            }

            // Keyboard ESC to close modals
            window.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    document.querySelectorAll('.modal-overlay.open').forEach(m => m.classList.remove('open'));
                }
            });

            // Backdrop click to close modals
            document.querySelectorAll('.modal-overlay').forEach(overlay => {
                overlay.addEventListener('click', (e) => {
                    if (e.target === overlay) {
                        overlay.classList.remove('open');
                    }
                });
            });
        });
    