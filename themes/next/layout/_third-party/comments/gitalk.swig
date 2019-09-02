<!-- gitalk 评论系统 2019.8.19 -->
{% if page.comments && theme.gitalk.enable %}
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.css">
  <script src="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.min.js"></script>
  <script type="text/javascript">
    const gitalk = new Gitalk({
      clientID: '{{theme.gitalk.clientID}}',
      clientSecret: '{{theme.gitalk.clientSecret}}',
      repo: '{{theme.gitalk.repo}}',
      owner: '{{theme.gitalk.githubID}}',
      admin: ['{{theme.gitalk.adminUser}}'],
	  id: '<%= page.date %>'
    })
    gitalk.render('gitalk-container')
  </script>
{% endif %}
