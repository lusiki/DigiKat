(function (root, factory) {
  var api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  root.DigiKatMojMedij = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  var PLATFORM = {
    web: "web",
    youtube: "YouTube",
    facebook: "Facebook",
    instagram: "Instagram",
    tiktok: "TikTok",
    twitter: "Twitter / X",
    reddit: "Reddit",
    forum: "forum",
    comment: "komentari"
  };
  var WEEKDAY = [
    "ponedjeljkom", "utorkom", "srijedom", "četvrtkom",
    "petkom", "subotom", "nedjeljom"
  ];

  function finite(value) {
    return typeof value === "number" && Number.isFinite(value);
  }

  function int(value) {
    return Math.round(value).toLocaleString("hr-HR");
  }

  function dec(value, digits) {
    return value.toLocaleString("hr-HR", {
      minimumFractionDigits: digits,
      maximumFractionDigits: digits
    });
  }

  function fold(value) {
    return String(value || "")
      .toLocaleLowerCase("hr-HR")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/đ/g, "dj")
      .trim();
  }

  function profilePlatforms(source) {
    var platforms = [];
    if (source && source.pl) platforms.push(source.pl);
    (source && source.bh || []).forEach(function (profile) {
      if (profile && profile.pl && platforms.indexOf(profile.pl) < 0) platforms.push(profile.pl);
    });
    return platforms;
  }

  function primaryProfile(source) {
    var profiles = (source && source.bh || []).filter(function (profile) {
      return profile && profile.pl;
    }).slice();
    profiles.sort(function (a, b) {
      return (finite(b.p) ? b.p : 0) - (finite(a.p) ? a.p : 0) ||
        String(a.pl).localeCompare(String(b.pl), "hr");
    });
    return profiles[0] || null;
  }

  function platformName(code) {
    return PLATFORM[code] || code || "nepoznatoj platformi";
  }

  function bestAttentionCandidate(source, policy) {
    var minimumPeers = Math.max(20, Number(policy && policy.findings_min_peers) || 0);
    var minimumGap = Number(policy && policy.findings_min_attention_gap_pp) || 5;
    var candidates = [];

    (source && source.bh || []).forEach(function (profile) {
      if (!profile || !profile.pl) return;
      var attention = profile.a || {};
      [
        { value: attention.t, peer: attention.mt, peers: attention.nt, metric: "top" },
        { value: attention.z, peer: attention.mz, peers: attention.nz, metric: "zero" }
      ].forEach(function (candidate) {
        if (!finite(candidate.value) || !finite(candidate.peer) || !finite(candidate.peers)) return;
        var gap = candidate.value - candidate.peer;
        if (candidate.peers < minimumPeers || Math.abs(gap) < minimumGap) return;
        candidates.push({
          profile: profile,
          metric: candidate.metric,
          value: candidate.value,
          peer: candidate.peer,
          peers: candidate.peers,
          gap: gap
        });
      });
    });

    candidates.sort(function (a, b) {
      return Math.abs(b.gap) - Math.abs(a.gap) ||
        (finite(b.profile.p) ? b.profile.p : 0) - (finite(a.profile.p) ? a.profile.p : 0) ||
        String(a.profile.pl).localeCompare(String(b.profile.pl), "hr");
    });
    return candidates[0] || null;
  }

  function bestTopicCandidate(source, data) {
    var topicPolicy = data && data.behaviour && data.behaviour.topics || {};
    var minimumPosts = Number(topicPolicy.min_classified_posts) ||
      Number(data && data.policy && data.policy.topic_min_classified_posts) || 100;
    var minimumPeers = Math.max(20, Number(data && data.policy && data.policy.findings_min_peers) || 0);
    var minimumGap = Number(data && data.policy && data.policy.findings_min_topic_gap_pp) || 5;
    var labels = topicPolicy.labels || [];
    var candidates = [];

    (source && source.bh || []).forEach(function (profile) {
      if (!profile || !profile.pl) return;
      var topics = profile.tm;
      if (!topics || !finite(topics.n) || topics.n < minimumPosts ||
          !finite(topics.pn) || topics.pn < minimumPeers ||
          !Array.isArray(topics.s) || !Array.isArray(topics.f)) return;
      labels.forEach(function (label, index) {
        var value = topics.s[index];
        var peer = topics.f[index];
        if (!finite(value) || !finite(peer)) return;
        var gap = value - peer;
        if (Math.abs(gap) < minimumGap) return;
        candidates.push({
          profile: profile,
          label: label,
          value: value,
          peer: peer,
          peers: topics.pn,
          posts: topics.n,
          gap: gap
        });
      });
    });

    candidates.sort(function (a, b) {
      return Math.abs(b.gap) - Math.abs(a.gap) ||
        b.posts - a.posts || a.label.localeCompare(b.label, "hr");
    });
    return candidates[0] || null;
  }

  function bestRhythmCandidate(source, data) {
    var minimumPosts = Number(data && data.behaviour && data.behaviour.rhythm &&
      data.behaviour.rhythm.min_cell_posts) ||
      Number(data && data.policy && data.policy.rhythm_min_cell_posts) || 20;
    var candidates = [];

    (source && source.bh || []).forEach(function (profile) {
      if (!profile || !profile.pl) return;
      (profile.r || []).forEach(function (cell) {
        if (!finite(cell.p) || cell.p < minimumPosts || !finite(cell.d) || !finite(cell.b)) return;
        candidates.push({ profile: profile, cell: cell });
      });
    });

    candidates.sort(function (a, b) {
      return b.cell.p - a.cell.p || a.cell.d - b.cell.d || a.cell.b - b.cell.b ||
        String(a.profile.pl).localeCompare(String(b.profile.pl), "hr");
    });
    return candidates[0] || null;
  }

  function createFindings(source, data) {
    var candidates = [];
    var policy = data && data.policy || {};
    var totals = data && data.totals || {};
    var minimumPosts = Number(policy.min_posts) || 100;

    if (source && finite(source.p) && source.p >= minimumPosts) {
      var scaleText = "U službenom korpusu ovaj profil ima " + int(source.p) + " objava";
      if (finite(source.rp) && finite(totals.sources_listed)) {
        scaleText += ". Po broju objava zauzima " + int(source.rp) + ". mjesto među " +
          int(totals.sources_listed) + " prikazanih izvora";
      }
      scaleText += ".";
      candidates.push({
        kind: "scale",
        priority: 10,
        title: "Opseg u korpusu",
        text: scaleText,
        support: { posts: source.p, minimum_posts: minimumPosts }
      });
    }

    var attention = bestAttentionCandidate(source, policy);
    if (attention) {
      var attentionText;
      if (attention.metric === "top") {
        attentionText = "Na platformi " + platformName(attention.profile.pl) +
          " deset vodećih objava nosi " + dec(attention.value, 1) +
          " % zabilježenih interakcija. Medijan među " + int(attention.peers) +
          " usporedivih izvora na istoj platformi iznosi " + dec(attention.peer, 1) + " %.";
      } else {
        attentionText = "Na platformi " + platformName(attention.profile.pl) + " " +
          dec(attention.value, 1) + " % objava nema zabilježenu interakciju. Medijan među " +
          int(attention.peers) + " usporedivih izvora na istoj platformi iznosi " +
          dec(attention.peer, 1) + " %.";
      }
      candidates.push({
        kind: "attention",
        priority: 20,
        title: "Kako se pažnja raspoređuje",
        text: attentionText,
        platform: attention.profile.pl,
        support: {
          source_value: attention.value,
          peer_value: attention.peer,
          peer_count: attention.peers,
          minimum_gap_pp: Number(policy.findings_min_attention_gap_pp) || 5
        }
      });
    }

    var topic = bestTopicCandidate(source, data || {});
    if (topic) {
      var relation = topic.gap > 0 ? "više" : "manje";
      candidates.push({
        kind: "topic",
        priority: 30,
        title: "Tema koja najviše odstupa",
        text: "Prema privremenom rječniku tema „" + topic.label + "” zastupljena je " + relation +
          " nego u usporedivoj skupini na platformi " + platformName(topic.profile.pl) + ". Udio iznosi " +
          dec(topic.value, 1) + " %, a prosjek " + int(topic.peers) +
          " izvora na istoj platformi iznosi " + dec(topic.peer, 1) + " %.",
        platform: topic.profile.pl,
        support: {
          classified_posts: topic.posts,
          peer_count: topic.peers,
          gap_pp: topic.gap,
          minimum_gap_pp: Number(data && data.policy && data.policy.findings_min_topic_gap_pp) || 5
        }
      });
    }

    var rhythm = bestRhythmCandidate(source, data || {});
    if (rhythm) {
      var bands = data && data.behaviour && data.behaviour.rhythm &&
        data.behaviour.rhythm.bands || [];
      candidates.push({
        kind: "rhythm",
        priority: 40,
        title: "Najčešći termin objave",
        text: "Na platformi " + platformName(rhythm.profile.pl) + " najviše je objava zabilježeno " +
          (WEEKDAY[rhythm.cell.d - 1] || "u odabranom danu") + " u pojasu " +
          (bands[rhythm.cell.b - 1] || rhythm.cell.b) + ". U toj je ćeliji " + int(rhythm.cell.p) +
          " objava. To opisuje raspored prikupljenih objava i ne procjenjuje učinak termina.",
        platform: rhythm.profile.pl,
        support: {
          posts: rhythm.cell.p,
          minimum_posts: Number(data && data.behaviour && data.behaviour.rhythm &&
            data.behaviour.rhythm.min_cell_posts) || 20
        }
      });
    }

    candidates.sort(function (a, b) {
      return a.priority - b.priority || a.kind.localeCompare(b.kind, "hr");
    });
    return candidates.slice(0, 3);
  }

  function findRequestedSource(sources, requestedName, requestedPlatform) {
    if (!Array.isArray(sources) || !requestedName) return null;
    var foldedName = fold(requestedName);
    var platform = fold(requestedPlatform);
    var matches = sources.filter(function (source) {
      if (fold(source && source.n) !== foldedName) return false;
      return !platform || profilePlatforms(source).some(function (value) {
        return fold(value) === platform;
      });
    });
    if (!matches.length) return null;
    var exact = matches.filter(function (source) {
      return String(source.n) === String(requestedName);
    });
    return exact[0] || matches[0];
  }

  function shareParameters(source) {
    var profile = primaryProfile(source);
    return {
      medij: source && source.n || "",
      platforma: profile && profile.pl || ""
    };
  }

  return {
    createFindings: createFindings,
    findRequestedSource: findRequestedSource,
    fold: fold,
    platformName: platformName,
    primaryProfile: primaryProfile,
    profilePlatforms: profilePlatforms,
    shareParameters: shareParameters
  };
});
