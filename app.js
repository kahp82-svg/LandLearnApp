(function () {
  var STORAGE_KEY = 'land-learn-progress-v1';

  var MODULES = [
    {
      id: '01-start',
      num: 1,
      title: '토지, 왜 \'땅\'이 돈이 되나요?',
      hook: '월급만으론 답이 없다는 걸, 5분이면 이해합니다.',
      href: 'lessons/01-start.html',
      minutes: 5,
      available: true,
    },
    {
      id: '02-timing',
      num: 2,
      title: '발표 전 vs 발표 후',
      hook: '계획만 나와도 값이 움직입니다. 타이밍이 전부예요.',
      href: 'lessons/02-timing.html',
      minutes: 6,
      available: true,
    },
    {
      id: '03-location',
      num: 3,
      title: '입지 읽는 법',
      hook: '역·도로·산업단지 = 사람이 모이는 자석.',
      href: 'lessons/03-location.html',
      minutes: 7,
      available: true,
    },
    {
      id: '04-check',
      num: 4,
      title: '사기 전 5가지 확인',
      hook: '등기·지적·실거래 — 이것만 보면 절반은 끝.',
      href: 'lessons/04-check.html',
      minutes: 8,
      available: true,
    },
    {
      id: '05-share',
      num: 5,
      title: '통째로 못 사도 된다',
      hook: '공유지분으로 먼저 선점하는 방법.',
      href: 'lessons/05-share.html',
      minutes: 6,
      available: true,
    },
    {
      id: '06-risk',
      num: 6,
      title: '이건 조심하세요',
      hook: '무서운 이야기가 아니라, 피하는 법을 알려드려요.',
      href: 'lessons/06-risk.html',
      minutes: 7,
      available: true,
    },
    {
      id: '07-action',
      num: 7,
      title: '오늘부터 할 수 있는 한 가지',
      hook: '완벽할 필요 없어요. 한 걸음만.',
      href: 'lessons/07-action.html',
      minutes: 5,
      available: true,
    },
  ];

  function homeHref() {
    var el = document.body && document.body.getAttribute('data-home');
    return el || 'index.html';
  }

  function readProgress() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch (e) {
      return {};
    }
  }

  function writeProgress(data) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    } catch (e) {}
  }

  function isDone(id) {
    return !!readProgress()[id];
  }

  function markDone(id) {
    var data = readProgress();
    data[id] = { doneAt: Date.now() };
    writeProgress(data);
  }

  function countDone() {
    return MODULES.filter(function (m) {
      return m.available && isDone(m.id);
    }).length;
  }

  function countAvailable() {
    return MODULES.filter(function (m) {
      return m.available;
    }).length;
  }

  function lessonHref(href) {
    var base = document.body && document.body.getAttribute('data-lesson-base');
    if (base) return base + href.replace(/^lessons\//, '');
    return href;
  }

  function renderRoadmap(container) {
    if (!container) return;

    var done = countDone();
    var total = countAvailable();
    var pct = total ? Math.round((done / total) * 100) : 0;

    var allDone = total > 0 && done >= total;
    var noteText = allDone
      ? done + ' / ' + total + ' 완료 · 1.0 코스 완주!'
      : done + ' / ' + total + ' 완료 · 하루 5분이면 한 장씩!';
    var completeBanner = allDone
      ? '<section class="learn-complete-banner fade-in-scroll is-visible" role="status">' +
        '<p class="learn-complete-banner__title">7장 모두 완료!</p>' +
        '<p class="learn-complete-banner__body">입문·실전 1.0을 끝냈어요. 이제 뉴스·지도를 다르게 볼 수 있어요.</p>' +
        '</section>'
      : '';

    var progressHtml =
      completeBanner +
      '<div class="learn-progress fade-in-scroll is-visible">' +
      '<div class="learn-progress__head">' +
      '<span class="learn-progress__label">내 진행률</span>' +
      '<span class="learn-progress__pct">' + pct + '%</span>' +
      '</div>' +
      '<div class="learn-progress__track" role="progressbar" aria-valuenow="' + pct + '" aria-valuemin="0" aria-valuemax="100">' +
      '<div class="learn-progress__fill" style="width:' + pct + '%"></div>' +
      '</div>' +
      '<p class="learn-progress__note">' + noteText + '</p>' +
      '</div>';

    var cards = MODULES.map(function (mod) {
      var completed = isDone(mod.id);
      var stateClass = completed
        ? ' learn-module--done'
        : mod.available
          ? ' learn-module--ready'
          : ' learn-module--soon';
      var badge = completed ? '완료' : mod.available ? '시작 가능' : '곧 공개';
      var href = mod.available ? lessonHref(mod.href) : '#';
      var tag = mod.available ? 'a' : 'div';
      var attrs =
        tag === 'a'
          ? ' href="' + href + '" class="learn-module' + stateClass + '"'
          : ' class="learn-module' + stateClass + '" aria-disabled="true"';

      return (
        '<' + tag + attrs + '>' +
        '<span class="learn-module__num">' + mod.num + '</span>' +
        '<span class="learn-module__body">' +
        '<span class="learn-module__badge">' + badge + '</span>' +
        '<span class="learn-module__title">' + mod.title + '</span>' +
        '<span class="learn-module__hook">' + mod.hook + '</span>' +
        '<span class="learn-module__meta">약 ' + mod.minutes + '분</span>' +
        '</span>' +
        (mod.available && !completed ? '<span class="learn-module__arrow" aria-hidden="true">→</span>' : '') +
        '</' + tag + '>'
      );
    }).join('');

    container.innerHTML = progressHtml + '<div class="learn-roadmap">' + cards + '</div>';
  }

  function moduleById(id) {
    for (var i = 0; i < MODULES.length; i++) {
      if (MODULES[i].id === id) return MODULES[i];
    }
    return null;
  }

  function initQuiz(root) {
    if (!root) return;

    var moduleId = root.getAttribute('data-module-id');
    var mod = moduleById(moduleId);
    var completeLabel = mod ? mod.num + '장 완료! 로드맵으로 →' : '완료! 로드맵으로 →';
    var feedback = root.querySelector('[data-quiz-feedback]');
    var completeBtn = document.querySelector('[data-learn-complete]');
    var home = homeHref();

    root.querySelectorAll('[data-quiz-option]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var correct = btn.getAttribute('data-correct') === 'true';
        root.querySelectorAll('[data-quiz-option]').forEach(function (b) {
          b.disabled = true;
          b.classList.remove('is-selected', 'is-wrong');
          if (b.getAttribute('data-correct') === 'true') {
            b.classList.add('is-correct');
          }
        });
        btn.classList.add(correct ? 'is-selected' : 'is-wrong');

        if (feedback) {
          feedback.hidden = false;
          feedback.className =
            'learn-quiz__feedback ' + (correct ? 'is-success' : 'is-encourage');
          feedback.textContent = correct
            ? feedback.getAttribute('data-msg-ok') ||
              '정답! 바로 그거예요. 이 감각만 있으면 충분합니다.'
            : feedback.getAttribute('data-msg-no') ||
              '괜찮아요. 위 내용 한 번만 더 보면 바로 와닿을 거예요.';
        }

        if (correct && completeBtn) {
          completeBtn.disabled = false;
          completeBtn.classList.add('is-ready');
        }
      });
    });

    function goHome() {
      location.href = home;
    }

    if (completeBtn) {
      if (isDone(moduleId)) {
        completeBtn.disabled = false;
        completeBtn.classList.add('is-ready');
        completeBtn.textContent = completeLabel;
        completeBtn.onclick = goHome;
      } else {
        completeBtn.addEventListener('click', function () {
          if (completeBtn.disabled) return;
          markDone(moduleId);
          completeBtn.textContent = completeLabel;
          completeBtn.onclick = goHome;
        });
      }
    }
  }

  function initScroll() {
    document.documentElement.classList.add('js-ready');

    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      document.querySelectorAll('.fade-in-scroll').forEach(function (el) {
        el.classList.add('is-visible');
      });
      return;
    }

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: '0px 0px -30px 0px' }
    );

    document.querySelectorAll('.fade-in-scroll').forEach(function (el, index) {
      el.style.transitionDelay = Math.min(index * 0.08, 0.4) + 's';
      observer.observe(el);
    });
  }

  window.LandLearn = {
    MODULES: MODULES,
    isDone: isDone,
    markDone: markDone,
    renderRoadmap: renderRoadmap,
  };

  document.addEventListener('DOMContentLoaded', function () {
    initScroll();
    renderRoadmap(document.getElementById('learn-roadmap'));
    initQuiz(document.querySelector('[data-learn-quiz]'));
  });
})();
