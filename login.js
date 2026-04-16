document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');
    const errorMessage = document.getElementById('error-message');
    const usernameInput = document.getElementById('username');
    const passwordInput = document.getElementById('password');

    if (!loginForm || !errorMessage || !usernameInput || !passwordInput) {
        console.error('Login form elements not found');
        return;
    }

    loginForm.addEventListener('submit', function(event) {
        event.preventDefault();

        const username = usernameInput.value.trim();
        const password = passwordInput.value;

        errorMessage.textContent = '';

        if (username === '' || password === '') {
            errorMessage.textContent = 'Please enter both username and password.';
            return;
        }

        fetch('login_check.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: 'username=' + encodeURIComponent(username) +
                  '&password=' + encodeURIComponent(password)
        })
        .then(response => response.text().then(text => ({
            ok: response.ok,
            status: response.status,
            text: text
        })))
        .then(({ ok, status, text }) => {
            console.log('STATUS:', status);
            console.log('RAW RESPONSE:', text);

            if (!ok) {
                errorMessage.textContent = 'Server error: ' + status;
                return;
            }

            let data;
            try {
                data = JSON.parse(text);
                console.log('PARSED DATA:', data);
            } catch (e) {
                console.error('Invalid JSON:', text);
                errorMessage.textContent = 'Invalid server response';
                return;
            }

            if (data.success) {
              console.log("User role:", data.role);

              if (data.role === "driver") {
                  window.location.href = "DriverDash.html";
              } else if (data.role === "warehouse staff") {
                  window.location.href = "WarehouseDash.html";
              } else {
                  errorMessage.textContent = "Dashboard under construction: " + data.role;
              }
            } else {
                errorMessage.textContent = data.message || 'Login failed';
            }
        })
        .catch(error => {
            console.error('Login fetch failed:', error);
            errorMessage.textContent = 'An error occurred. Please try again.';
        });
    });
});
