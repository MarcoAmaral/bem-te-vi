# Requirements: Password reset

Source: SAMPLE-1 (a fixture ticket; see tests/test-qa-trace.sh)

1. A registered email address receives a password reset link. — Origin: AC-1
2. A password reset link stops working 30 minutes after it is sent. — Origin: AC-2
3. An unregistered email address gets the same confirmation message as a registered one. — Origin: AC-3
4. A new password shorter than 12 characters is rejected. — Origin: AC-4
5. A password reset link works only once. — Origin: AC-5
