
document.addEventListener('DOMContentLoaded', function () {
  emailjs.init('r-mbwPfodQh82SAq_');

  document
    .getElementById('contact-form')
    .addEventListener('submit', function (event) {
      event.preventDefault();

      const formData = {
        company: document.getElementById('company').value,
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        phone: document.getElementById('phone').value,
        message: document.getElementById('message').value,
      };

      emailjs
        .send('service_joy','template_22acszj', formData)
        .then(function (response) {
          alert('문의가 성공적으로 접수되었습니다. 감사합니다.');
          location.href = './index.html';
        })
        .catch(function (error) {
          console.error('이메일 전송 실패:', error);
          alert(
            '죄송합니다, 문의 접수가 실패했습니다. 잠시 후 다시 시도해 주세요.'
          );
        });
    });
});

